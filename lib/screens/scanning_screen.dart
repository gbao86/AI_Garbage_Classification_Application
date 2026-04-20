import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phan_loai_rac_qua_hinh_anh/services/segmentation_service.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/result_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/services/gemini_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ScanningScreen extends StatefulWidget {
  final File image;
  final Interpreter? classifierInterpreter;
  final List<String> labels;
  final Map<String, String> labelTranslations;
  final String Function({
  required String translatedLabel,
  required String originalLabel,
  required String classification,
  required double confidencePct,
  required bool lowConfidence,
  }) buildLocalGuidanceMarkdown;

  const ScanningScreen({
    super.key,
    required this.image,
    required this.classifierInterpreter,
    required this.labels,
    required this.labelTranslations,
    required this.buildLocalGuidanceMarkdown,
  });

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late AnimationController _shimmerController;

  ui.Image? _sharpUiImage; // Ảnh gốc chuẩn tỷ lệ EXIF
  ui.Image? _maskImage;    // Mask vật thể từ ML Kit

  String? _label;
  String? _finalMarkdown;
  
  // Lưu thông tin TFLite để báo cáo
  String? _tfliteLabel;
  double _tfliteConfidence = 0.0;

  bool _isScanCompleted = false; // Đánh dấu tia laser đã quét xong
  bool _isGeminiRunning = false;

  final SegmentationService _segmentationService = SegmentationService();
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();

    _scanLineController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3000)
    );

    _scanLineController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isScanCompleted = true);
        _runSegmentation();
      }
    });

    _shimmerController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000)
    )..repeat();

    _loadSharpImage().then((img) {
      if (mounted) {
        setState(() => _sharpUiImage = img);
        _scanLineController.forward();
        _startBackgroundAI();
      }
    });
  }

  Future<ui.Image> _loadSharpImage() async {
    final completer = Completer<ui.Image>();
    final imageProvider = FileImage(widget.image);
    final stream = imageProvider.resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((info, _) {
      completer.complete(info.image);
    }));
    return completer.future;
  }

  Future<void> _runSegmentation() async {
    if (_sharpUiImage == null) return;
    final mask = await _segmentationService.getMask(widget.image, _sharpUiImage!.width, _sharpUiImage!.height);
    if (mounted) {
      setState(() => _maskImage = mask);
      _checkAndNavigate();
    }
  }

  Future<void> _startBackgroundAI() async {
    final offlineResult = await _classifyLocal();
    if (mounted) {
      setState(() {
        _label = offlineResult.label;
        _finalMarkdown = offlineResult.markdown;
        _tfliteLabel = offlineResult.originalLabel;
        _tfliteConfidence = offlineResult.confidence;
      });
    }

    if (offlineResult.confidence < 0.8) {
      setState(() => _isGeminiRunning = true);
      final geminiResult = await _geminiService.processImageAndGetGuidance(widget.image);
      if (mounted) {
        setState(() {
          _label = "Đã phân tích bằng AI";
          _finalMarkdown = geminiResult;
          _isGeminiRunning = false;
        });
        _checkAndNavigate();
      }
    } else {
      _checkAndNavigate();
    }
  }

  static List<List<List<double>>> _preprocessForClassifier(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return [];
    final resized = img.copyResize(image, width: 224, height: 224);
    return List.generate(224, (y) =>
        List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble()];
        })
    );
  }

  Future<({String label, String originalLabel, String markdown, double confidence})> _classifyLocal() async {
    if (widget.classifierInterpreter == null || widget.labels.isEmpty) {
      return (label: 'Lỗi', originalLabel: 'N/A', markdown: 'Mô hình chưa sẵn sàng', confidence: 0.0);
    }
    try {
      final imageBytes = await widget.image.readAsBytes();
      final inputData = await compute(_preprocessForClassifier, imageBytes);
      if (inputData.isEmpty) return (label: 'Lỗi', originalLabel: 'N/A', markdown: 'Lỗi xử lý ảnh', confidence: 0.0);

      final input = [inputData];
      final output = List.generate(1, (_) => List.filled(widget.labels.length, 0.0));
      widget.classifierInterpreter!.run(input, output);

      final maxScore = output[0].reduce((a, b) => a > b ? a : b);
      final maxScoreIndex = output[0].indexOf(maxScore);

      String originalLabel = widget.labels[maxScoreIndex].trim().replaceFirst(RegExp(r'^\d+\s+'), '');
      final translatedLabel = widget.labelTranslations[originalLabel] ?? originalLabel;

      final markdown = widget.buildLocalGuidanceMarkdown(
        translatedLabel: translatedLabel,
        originalLabel: originalLabel,
        classification: _getClassification(originalLabel),
        confidencePct: maxScore * 100,
        lowConfidence: maxScore < 0.8,
      );
      return (label: translatedLabel, originalLabel: originalLabel, markdown: markdown, confidence: maxScore);
    } catch (e) {
      return (label: 'Lỗi', originalLabel: 'N/A', markdown: 'Lỗi: $e', confidence: 0.0);
    }
  }

  String _getClassification(String label) {
    final l = label.toLowerCase();
    const recyclable = ['glass', 'cardboard', 'paper', 'plastic', 'metal', 'clothes', 'shoes'];
    if (l.contains('battery')) return 'nguy hại';
    if (l.contains('biological')) return 'hữu cơ';
    if (recyclable.any((item) => l.contains(item))) return 'tái chế';
    return 'không tái chế';
  }

  void _checkAndNavigate() {
    if (_isScanCompleted && _maskImage != null && !_isGeminiRunning && _finalMarkdown != null) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                image: widget.image,
                processingResult: _finalMarkdown!,
                tfliteLabel: _tfliteLabel,
                tfliteConfidence: _tfliteConfidence,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_sharpUiImage == null)
            RepaintBoundary(child: Image.file(widget.image, fit: BoxFit.cover)),

          if (_sharpUiImage != null)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_scanLineController, _shimmerController]),
                builder: (context, child) {
                  return CustomPaint(
                    painter: SmartScanPainter(
                      sharpUiImage: _sharpUiImage!,
                      maskImage: _maskImage,
                      scanProgress: _scanLineController.value,
                      shimmerProgress: _shimmerController.value,
                      isScanCompleted: _isScanCompleted,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),

          if (!_isScanCompleted)
            AnimatedBuilder(
              animation: _scanLineController,
              builder: (context, child) {
                return Positioned(
                  top: size.height * _scanLineController.value,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(color: Colors.blueAccent.withOpacity(0.9), blurRadius: 20, spreadRadius: 3),
                        BoxShadow(color: Colors.white, blurRadius: 5, spreadRadius: 1),
                      ],
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

          Positioned(
            bottom: 120,
            left: 40,
            right: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(animation), child: child));
                  },
                  child: _label != null
                      ? Text(_label!, key: ValueKey<String>(_label!), style: TextStyle(color: const Color(0xFF6CFFA0), fontSize: 42, fontWeight: FontWeight.w700, letterSpacing: 1.2, shadows: [Shadow(color: Colors.black.withOpacity(0.9), blurRadius: 15, offset: const Offset(0, 4)), Shadow(color: const Color(0xFF6CFFA0).withOpacity(0.6), blurRadius: 12)],), textAlign: TextAlign.center)
                      : const SizedBox.shrink(key: ValueKey('empty_label')),
                ),
                const SizedBox(height: 20),
                if (_isGeminiRunning || _label == null || (!_isScanCompleted))
                  const TypewriterText(text: "Đang phân tích cấu trúc..."),
              ],
            ),
          ),

          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _shimmerController.dispose();
    _segmentationService.dispose();
    super.dispose();
  }
}

class SmartScanPainter extends CustomPainter {
  final ui.Image sharpUiImage;
  final ui.Image? maskImage;
  final double scanProgress;
  final double shimmerProgress;
  final bool isScanCompleted;

  SmartScanPainter({required this.sharpUiImage, required this.maskImage, required this.scanProgress, required this.shimmerProgress, required this.isScanCompleted});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paintImage(canvas: canvas, rect: rect, image: sharpUiImage, fit: BoxFit.cover);

    if (!isScanCompleted) {
      double currentY = size.height * scanProgress;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, currentY), Paint()..color = Colors.black.withOpacity(0.4));
      return;
    }

    if (maskImage != null) {
      canvas.saveLayer(rect, Paint());
      final blurPaint = Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12);
      canvas.saveLayer(rect, blurPaint);
      paintImage(canvas: canvas, rect: rect, image: sharpUiImage, fit: BoxFit.cover);
      canvas.restore();
      canvas.drawRect(rect, Paint()..color = Colors.black.withOpacity(0.45));
      canvas.saveLayer(rect, Paint()..blendMode = BlendMode.dstOut);
      paintImage(canvas: canvas, rect: rect, image: maskImage!, fit: BoxFit.cover);
      canvas.restore();
      canvas.restore();

      canvas.saveLayer(rect, Paint());
      paintImage(canvas: canvas, rect: rect, image: maskImage!, fit: BoxFit.cover);
      final shimmerPaint = Paint()..blendMode = BlendMode.srcIn..shader = ui.Gradient.linear(Offset(size.width * (shimmerProgress * 2 - 1.0), 0), Offset(size.width * (shimmerProgress * 2), 0), [const Color(0x006CFFA0), const Color(0xFF6CFFA0).withOpacity(0.6), const Color(0x006CFFA0)], [0.0, 0.5, 1.0]);
      canvas.drawRect(rect, shimmerPaint);
      canvas.restore();
    } else {
      final blurPaint = Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12);
      canvas.saveLayer(rect, blurPaint);
      paintImage(canvas: canvas, rect: rect, image: sharpUiImage, fit: BoxFit.cover);
      canvas.restore();
      canvas.drawRect(rect, Paint()..color = Colors.black.withOpacity(0.3));
    }
  }

  @override
  bool shouldRepaint(covariant SmartScanPainter oldDelegate) => true;
}

class TypewriterText extends StatefulWidget {
  final String text;
  const TypewriterText({super.key, required this.text});
  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 2500), vsync: this)..repeat();
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(_controller);
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _characterCount, builder: (context, child) {
      String text = widget.text.substring(0, _characterCount.value);
      return Text(text, style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic, shadows: [Shadow(color: Colors.black, blurRadius: 5)]));
    });
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}

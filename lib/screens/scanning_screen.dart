import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:phan_loai_rac_qua_hinh_anh/services/segmentation_service.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/result_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/services/gemini_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;

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

class _ScanningScreenState extends State<ScanningScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.Image? _maskImage;
  String? _label;
  String? _finalMarkdown;
  bool _isGeminiRunning = false;
  final SegmentationService _segmentationService = SegmentationService();
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _startAnalysis();
    _controller.forward().then((_) {
      _checkAndNavigate();
    });
  }

  Future<void> _startAnalysis() async {
    // Flow 1: Shape Extraction
    _segmentationService.getMask(widget.image).then((mask) {
      if (mounted) {
        setState(() {
          _maskImage = mask;
        });
      }
    });

    // Flow 2: Local Labeling
    final offlineResult = await _classifyLocal();
    
    if (mounted) {
      setState(() {
        _label = offlineResult.label;
        _finalMarkdown = offlineResult.markdown;
      });
    }

    // Flow 3: API Decision
    if (offlineResult.confidence < 0.8) {
      setState(() => _isGeminiRunning = true);
      _geminiService.processImageAndGetGuidance(widget.image).then((geminiResult) {
        if (mounted) {
          setState(() {
            _finalMarkdown = geminiResult;
            _isGeminiRunning = false;
          });
          if (_controller.isCompleted) {
            _navigateToResult();
          }
        }
      });
    }
  }

  Future<({String label, String markdown, double confidence})> _classifyLocal() async {
    if (widget.classifierInterpreter == null || widget.labels.isEmpty) {
      return (label: 'Lỗi', markdown: 'Mô hình chưa sẵn sàng', confidence: 0.0);
    }
    try {
      final imageBytes = await widget.image.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return (label: 'Lỗi', markdown: 'Không thể giải mã ảnh', confidence: 0.0);

      final resizedImage = img.copyResize(image, width: 224, height: 224);
      final input = List.generate(1, (_) => List.generate(224, (_) => List.generate(224, (_) => List.filled(3, 0.0))));

      for (var x = 0; x < 224; x++) {
        for (var y = 0; y < 224; y++) {
          final pixel = resizedImage.getPixel(x, y);
          input[0][x][y][0] = pixel.r.toDouble();
          input[0][x][y][1] = pixel.g.toDouble();
          input[0][x][y][2] = pixel.b.toDouble();
        }
      }

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

      return (label: translatedLabel, markdown: markdown, confidence: maxScore);
    } catch (e) {
      return (label: 'Lỗi', markdown: 'Lỗi: $e', confidence: 0.0);
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
    if (!_isGeminiRunning && _finalMarkdown != null) {
      _navigateToResult();
    }
  }

  void _navigateToResult() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          image: widget.image,
          processingResult: _finalMarkdown ?? 'Đang xử lý...',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer A: Original Image
          Image.file(widget.image, fit: BoxFit.cover),

          // Layer B: Mask Layer (via CustomPainter)
          if (_maskImage != null)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: SmartScanPainter(_maskImage!, _controller.value),
                  size: Size.infinite,
                );
              },
            ),

          // Layer C: Scan Line
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * _controller.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                    color: Colors.blueAccent,
                  ),
                ),
              );
            },
          ),

          // Label and Loading Text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_label != null)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Text(
                          _label!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                          ),
                        ),
                      );
                    },
                  ),
                if (_isGeminiRunning)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: TypewriterText(text: "Deep analysis in progress..."),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _segmentationService.dispose();
    super.dispose();
  }
}

class SmartScanPainter extends CustomPainter {
  final ui.Image maskImage;
  final double scanProgress;

  SmartScanPainter(this.maskImage, this.scanProgress);

  @override
  void paint(Canvas canvas, Size size) {
    double currentY = size.height * scanProgress;

    // 1. Light overlay for scanned area (dark background)
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, currentY), backgroundPaint);

    // 2. Highlight Object
    final paint = Paint();
    
    canvas.save();
    // Only draw what's above the scan line
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, currentY));
    
    // Scale mask to screen size
    double scaleX = size.width / maskImage.width;
    double scaleY = size.height / maskImage.height;
    
    // Use BlendMode to colorize the mask
    final objectPaint = Paint()
      ..colorFilter = ColorFilter.mode(Colors.greenAccent.withOpacity(0.3), ui.BlendMode.srcIn);

    canvas.scale(scaleX, scaleY);
    canvas.drawImage(maskImage, Offset.zero, objectPaint);
    
    // Shimmer effect (optional - simple implementation)
    final shimmerPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * (scanProgress - 0.2) / scaleX, 0),
        Offset(size.width * scanProgress / scaleX, 0),
        [
          Colors.transparent,
          Colors.white.withOpacity(0.2),
          Colors.transparent,
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, maskImage.width.toDouble(), maskImage.height.toDouble()), shimmerPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SmartScanPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _characterCount = StepTween(begin: 0, end: widget.text.length).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        String text = widget.text.substring(0, _characterCount.value);
        return Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

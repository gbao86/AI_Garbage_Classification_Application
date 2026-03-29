import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:phan_loai_rac_qua_hinh_anh/screens/result_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/services/gemini_service.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/about_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/map_screen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String _processingMessage = '';
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();
  Interpreter? _interpreter;
  List<String> _labels = [];
  int _currentIndex = 0;

  final Map<String, String> _labelTranslations = {
    'battery': 'Pin / Ắc quy',
    'biological': 'Rác hữu cơ / Sinh học',
    'brown-glass': 'Thủy tinh nâu',
    'cardboard': 'Bìa các-tông',
    'clothes': 'Quần áo',
    'green-glass': 'Thủy tinh xanh',
    'metal': 'Kim loại',
    'paper': 'Giấy',
    'plastic': 'Nhựa',
    'shoes': 'Giày dép',
    'trash': 'Rác thải thông thường',
    'white-glass': 'Thủy tinh trắng',
  };

  @override
  void initState() {
    super.initState();
    _initializeModelAndLabels();
  }

  Future<void> _initializeModelAndLabels() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model_unquant.tflite');
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      if (mounted) {
        setState(() {
          _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
        });
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo TFLite: $e');
    }
  }

  Future<File?> _convertToJpg(File file) async {
    final String extension = p.extension(file.path).toLowerCase();
    if (extension == '.heic' || extension == '.heif') {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, "${DateTime.now().millisecondsSinceEpoch}.jpg");
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path, targetPath, format: CompressFormat.jpeg, quality: 90,
      );
      return result != null ? File(result.path) : file;
    }
    return file;
  }

  Future<String> _classifyWithTFLite(File imageFile) async {
    if (_interpreter == null || _labels.isEmpty) return 'Lỗi: Mô hình chưa sẵn sàng.';
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return 'Lỗi: Không thể giải mã ảnh.';
      final resizedImage = img.copyResize(image, width: 224, height: 224);
      final input = List.generate(1, (_) => List.generate(224, (_) => List.generate(224, (_) => List.filled(3, 0.0))));
      for (var x = 0; x < 224; x++) {
        for (var y = 0; y < 224; y++) {
          final pixel = resizedImage.getPixel(x, y);
          input[0][x][y][0] = pixel.r / 255.0;
          input[0][x][y][1] = pixel.g / 255.0;
          input[0][x][y][2] = pixel.b / 255.0;
        }
      }
      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
      _interpreter!.run(input, output);
      final maxScore = output[0].reduce((a, b) => a > b ? a : b);
      final maxScoreIndex = output[0].indexOf(maxScore);
      
      String originalLabel = _labels[maxScoreIndex].trim();
      originalLabel = originalLabel.replaceFirst(RegExp(r'^\d+\s+'), ''); 

      if (maxScore * 100 < 40) return 'Lỗi: Độ tin cậy thấp.';
      
      final translatedLabel = _labelTranslations[originalLabel] ?? originalLabel;
      final classification = _getClassification(originalLabel);
      
      return '''**Loại rác**: $translatedLabel ($originalLabel)\n**Phân loại**: $classification\n**Độ tin cậy**: ${(maxScore * 100).toStringAsFixed(2)}%''';
    } catch (e) { return 'Lỗi: $e'; }
  }

  String _getClassification(String label) {
    final l = label.toLowerCase();
    const recyclable = ['brown-glass', 'green-glass', 'white-glass', 'cardboard', 'paper', 'plastic', 'metal', 'clothes', 'shoes'];
    if (l.contains('battery')) return 'nguy hại';
    if (l.contains('biological')) return 'hữu cơ';
    if (recyclable.any((item) => l.contains(item))) return 'tái chế';
    return 'không tái chế';
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;
      setState(() => _processingMessage = 'Đang chuẩn bị...');
      File? processedFile = await _convertToJpg(File(pickedFile.path));
      if (!mounted) return;
      setState(() { _image = processedFile; _processingMessage = 'Đang phân tích...'; });
      String result = await _classifyWithTFLite(_image!);
      if (result.startsWith('Lỗi')) {
        setState(() => _processingMessage = 'Đang dùng AI Gemini...');
        result = await _geminiService.processImageAndGetGuidance(_image!);
      }
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => ResultScreen(image: _image!, processingResult: result)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _processingMessage = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F3),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(height: 300, width: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.primaryColor.withOpacity(0.1))),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hành động nhỏ,', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54)),
                                Text('Vì môi trường xanh', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.primaryColor)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                              child: Icon(Icons.notifications_none_rounded, color: theme.primaryColor),
                            )
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withAlpha(180)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                              const SizedBox(height: 16),
                              const Text('Bảo vệ Trái Đất\nbằng Trí Tuệ Nhân Tạo', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
                              const SizedBox(height: 8),
                              Text('Phân loại đúng để tái chế hiệu quả hơn.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('Chức năng chính', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildActionCard(
                          context,
                          title: 'Máy ảnh',
                          subtitle: 'Quét rác trực tiếp',
                          icon: Icons.camera_rounded,
                          color: theme.primaryColor,
                          onTap: () => _processImage(ImageSource.camera),
                        ),
                        const SizedBox(height: 16),
                        _buildActionCard(
                          context,
                          title: 'Thư viện',
                          subtitle: 'Chọn ảnh từ máy',
                          icon: Icons.photo_library_rounded,
                          color: Colors.blue,
                          onTap: () => _processImage(ImageSource.gallery),
                        ),
                        if (_processingMessage.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Center(
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(_processingMessage, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavIcon(Icons.home_rounded, 'Trang chủ', _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                  _buildNavIcon(Icons.map_rounded, 'Bản đồ', _currentIndex == 1, onTap: () {
                    setState(() => _currentIndex = 1);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen()));
                  }),
                  _buildNavIcon(Icons.info_rounded, 'Thông tin', _currentIndex == 2, onTap: () {
                    setState(() => _currentIndex = 2);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.black26, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? theme.primaryColor : Colors.black26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isActive ? theme.primaryColor : Colors.black26, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}

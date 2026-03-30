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
    'biological': 'Rác hữu cơ',
    'cardboard': 'Bìa các-tông',
    'clothes': 'Quần áo',
    'glass': 'Thủy tinh',
    'metal': 'Kim loại',
    'paper': 'Giấy',
    'plastic': 'Nhựa',
    'shoes': 'Giày dép',
    'trash': 'Rác thông thường',
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

          // ĐÃ FIX: Chỉ lấy giá trị gốc và chuyển sang Double.
          // Mô hình TFLite sẽ tự động chia 255 ở bên trong nhờ lớp Rescaling.
          input[0][x][y][0] = pixel.r.toDouble();
          input[0][x][y][1] = pixel.g.toDouble();
          input[0][x][y][2] = pixel.b.toDouble();
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
    } catch (e) {
      return 'Lỗi: $e';
    }
  }

  // 2. Cập nhật logic phân loại cho đúng 10 nhãn mới
  String _getClassification(String label) {
    final l = label.toLowerCase();
    // Danh sách tái chế mới: gộp glass thay cho 3 loại glass cũ
    const recyclable = ['glass', 'cardboard', 'paper', 'plastic', 'metal', 'clothes', 'shoes'];
    
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
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hành động nhỏ, lợi ích lớn', style: theme.textTheme.bodyLarge),
                                Text('EcoSort by Bao', style: theme.textTheme.headlineMedium?.copyWith(color: theme.primaryColor)),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.notifications_none_rounded, color: theme.primaryColor),
                                onPressed: () {},
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildHeroBanner(theme),
                        const SizedBox(height: 40),
                        Text('Dịch vụ', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 20),
                        _buildActionGrid(theme),
                        const SizedBox(height: 32),
                        if (_processingMessage.isNotEmpty) _buildLoadingStatus(theme),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildCustomBottomNav(theme),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.eco_rounded, size: 120, color: Colors.white.withOpacity(0.1)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Text('AI Powered', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bảo vệ Trái Đất\nbằng Trí Tuệ Nhân Tạo',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Phân loại đúng để tái chế hiệu quả hơn.',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'Máy ảnh',
            subtitle: 'Quét trực tiếp',
            icon: Icons.camera_rounded,
            color: theme.primaryColor,
            onTap: () => _processImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildActionCard(
            title: 'Thư viện',
            subtitle: 'Chọn ảnh sẵn',
            icon: Icons.photo_library_rounded,
            color: Colors.blue.shade600,
            onTap: () => _processImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withOpacity(0.03)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black45, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: 16),
          Text(_processingMessage, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNav(ThemeData theme) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C1E),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Trang chủ', _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
            _buildNavItem(1, Icons.map_rounded, 'Bản đồ', _currentIndex == 1, onTap: () {
              setState(() => _currentIndex = 1);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen()));
            }),
            _buildNavItem(2, Icons.info_rounded, 'Thông tin', _currentIndex == 2, onTap: () {
              setState(() => _currentIndex = 2);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isSelected, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.greenAccent : Colors.white54, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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

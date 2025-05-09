import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:phan_loai_rac_qua_hinh_anh/screens/result_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/services/gemini_service.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String _processingMessage = '';
  final _geminiService = GeminiService();
  final _picker = ImagePicker();
  Interpreter? _interpreter;
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _initializeModelAndLabels();
  }

  Future<void> _initializeModelAndLabels() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model_unquant.tflite');
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      setState(() {
        _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      });
    } catch (e) {
      debugPrint('Lỗi khởi tạo TFLite hoặc nhãn: $e');
    }
  }

  Future<String> _classifyWithTFLite(File imageFile) async {
    if (_interpreter == null || _labels.isEmpty) {
      return 'Lỗi: Mô hình TFLite hoặc nhãn không được tải.';
    }

    try {
      // Đọc và xử lý ảnh
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return 'Lỗi: Không thể giải mã ảnh.';

      // Resize và chuẩn hóa ảnh
      final resizedImage = img.copyResize(image, width: 224, height: 224);
      final input = List.generate(1, (_) => List.generate(
        224, (_) => List.generate(224, (_) => List.filled(3, 0.0)),
      ));

      for (var x = 0; x < 224; x++) {
        for (var y = 0; y < 224; y++) {
          final pixel = resizedImage.getPixel(x, y);
          input[0][x][y][0] = pixel.r / 255.0;
          input[0][x][y][1] = pixel.g / 255.0;
          input[0][x][y][2] = pixel.b / 255.0;
        }
      }

      // Chạy mô hình
      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
      _interpreter!.run(input, output);

      // Tìm nhãn có xác suất cao nhất
      final maxScore = output[0].reduce((a, b) => a > b ? a : b);
      final maxScoreIndex = output[0].indexOf(maxScore);
      final label = _labels[maxScoreIndex];
      final confidence = maxScore * 100;

      // Định dạng kết quả
      final classification = _getClassification(label);
      return '''
**Loại rác**: $label
**Phân loại**: $classification
**Hướng dẫn xử lý**:
- **Cách vứt bỏ**: ${classification == 'tái chế' ? 'Cho vào thùng tái chế' : classification == 'hữu cơ' ? 'Cho vào thùng rác hữu cơ' : classification == 'nguy hại' ? 'Mang đến điểm thu gom đặc biệt' : 'Cho vào thùng rác thông thường'}
- **Nơi xử lý**: ${classification == 'tái chế' ? 'Trung tâm tái chế' : classification == 'hữu cơ' ? 'Nhà máy xử lý hữu cơ' : classification == 'nguy hại' ? 'Cơ sở xử lý chất thải nguy hại' : 'Bãi chôn lấp'}
- **Tác hại nếu xử lý sai**: ${classification == 'nguy hại' ? 'Ô nhiễm môi trường, ảnh hưởng sức khỏe' : 'Gây khó khăn cho quá trình tái chế hoặc xử lý'}
**Độ tin cậy**: ${confidence.toStringAsFixed(2)}%
      ''';
    } catch (e) {
      debugPrint('Lỗi phân loại TFLite: $e');
      return 'Lỗi phân loại TFLite: $e';
    }
  }

  String _getClassification(String label) {
    const recyclable = ['brown-glass', 'green-glass', 'white-glass', 'cardboard', 'paper', 'plastic', 'metal', 'clothes', 'shoes'];
    if (label == 'battery') return 'nguy hại';
    if (label == 'biological') return 'hữu cơ';
    if (recyclable.contains(label)) return 'tái chế';
    if (label == 'trash') return 'không tái chế';
    return 'không xác định';
  }

  Future<void> _processImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _processingMessage = 'Đang xử lý ảnh...';
    });

    try {
      // Thử TFLite trước, sau đó Gemini
      String result = await _classifyWithTFLite(_image!);
      String source = 'TFLite';
      if (result.startsWith('Lỗi')) {
        debugPrint('TFLite thất bại, chuyển sang Gemini API');
        result = await _geminiService.processImageAndGetGuidance(_image!);
        source = 'Gemini';
      } else {
        debugPrint('Phân loại thành công bằng TFLite');
      }

      // Thêm chỉ báo nguồn vào kết quả
      result = '$result\n**Nguồn**: $source';

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              image: _image!,
              processingResult: result,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi xử lý ảnh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xử lý ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingMessage = '';
          _image = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân Loại Rác AI'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/trash_illustration.png',
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  'Chụp hoặc chọn ảnh rác để phân loại và nhận hướng dẫn',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.camera_alt,
                      label: 'Chụp ảnh',
                      onPressed: () => _processImage(ImageSource.camera),
                    ),
                    _buildActionButton(
                      icon: Icons.photo_library,
                      label: 'Chọn ảnh',
                      onPressed: () => _processImage(ImageSource.gallery),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_processingMessage.isNotEmpty)
                  Text(
                    _processingMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
                BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Về ứng dụng'),
              ],
              onTap: (index) {
                if (index == 1 && mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AboutScreen()));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}
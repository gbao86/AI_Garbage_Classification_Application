import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/result_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/services/gemini_service.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/about_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String _processingMessage = '';
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _processImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _processingMessage = 'Đang xử lý ảnh...';
      });

      try {
        final result = await _geminiService.processImageAndGetGuidance(_image!);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              image: _image!,
              processingResult: result,
            ),
          ),
        );
      } catch (e) {
        setState(() {
          _processingMessage = 'Lỗi xử lý ảnh: $e';
          _image = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xảy ra lỗi: $e')),
        );
      } finally {
        setState(() {
          _processingMessage = '';
        });
      }
    } else {
      setState(() {
        _processingMessage = '';
      });
    }
  }

  Future<void> _takePicture() async {
    _processImage(ImageSource.camera);
  }

  Future<void> _pickFromGallery() async {
    _processImage(ImageSource.gallery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân Loại Rác AI'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/images/trash_illustration.png',
                    height: 150,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Chọn ảnh rác để phân loại và nhận hướng dẫn',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _takePicture,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Chụp ảnh'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Chọn ảnh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (_processingMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _processingMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
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
                if (index == 1) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AboutScreen()));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
//lib/widgets/camera_widget.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraConstants { // Đổi tên thành CameraConstants
  static const Color primaryColor = Colors.blue;
}

class CameraWidget extends StatefulWidget {
  final CameraDescription camera;
  final Function(XFile) onPictureTaken;

  const CameraWidget({Key? key, required this.camera, required this.onPictureTaken}) : super(key: key);

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final XFile picture = await _controller.takePicture();
    widget.onPictureTaken(picture);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: CameraPreview(_controller),
              ),
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Positioned(
                bottom: 20,
                child: FloatingActionButton(
                  onPressed: _takePicture,
                  child: Icon(Icons.camera),
                  backgroundColor: CameraConstants.primaryColor, // Sử dụng CameraConstants
                ),
              ),
            ],
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
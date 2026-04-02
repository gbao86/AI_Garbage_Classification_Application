import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class SegmentationService {
  Interpreter? _interpreter;
  static const int _inputSize = 257;

  Future<void> init() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/lite-model_deeplabv3_1_metadata_2.tflite');
    } catch (e) {
      debugPrint('Lỗi khởi tạo DeepLabV3: $e');
    }
  }

  Future<ui.Image?> getMask(File imageFile) async {
    if (_interpreter == null) await init();
    if (_interpreter == null) return null;

    try {
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;

      final inputImage = img.copyResize(originalImage, width: _inputSize, height: _inputSize);
      
      // Chuyển đổi ảnh sang tensor input [1, 257, 257, 3]
      var input = Float32List(_inputSize * _inputSize * 3);
      var buffer = input.buffer;
      int pixelIndex = 0;
      for (var y = 0; y < _inputSize; y++) {
        for (var x = 0; x < _inputSize; x++) {
          final pixel = inputImage.getPixel(x, y);
          input[pixelIndex++] = (pixel.r - 127.5) / 127.5;
          input[pixelIndex++] = (pixel.g - 127.5) / 127.5;
          input[pixelIndex++] = (pixel.b - 127.5) / 127.5;
        }
      }

      // Output tensor: [1, 257, 257, 21]
      var output = List.filled(1 * _inputSize * _inputSize * 21, 0.0).reshape([1, _inputSize, _inputSize, 21]);
      
      _interpreter!.run(buffer.asFloat32List().reshape([1, _inputSize, _inputSize, 3]), output);

      // Tạo mask từ output (argmax)
      final maskImg = img.Image(width: _inputSize, height: _inputSize);
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          int maxClass = 0;
          double maxVal = output[0][y][x][0];
          for (int c = 1; c < 21; c++) {
            if (output[0][y][x][c] > maxVal) {
              maxVal = output[0][y][x][c];
              maxClass = c;
            }
          }
          // maxClass > 0 nghĩa là có vật thể (0 là background)
          if (maxClass > 0) {
            maskImg.setPixel(x, y, img.ColorRgba8(255, 255, 255, 255));
          } else {
            maskImg.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
          }
        }
      }

      // Chuyển img.Image sang ui.Image
      final ui.ImmutableBuffer immutableBuffer = await ui.ImmutableBuffer.fromUint8List(Uint8List.fromList(img.encodePng(maskImg)));
      final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(immutableBuffer);
      final ui.Codec codec = await descriptor.instantiateCodec();
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      debugPrint('Lỗi xử lý Segmentation: $e');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}

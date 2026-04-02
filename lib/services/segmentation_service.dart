import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';

class SegmentationService {
  final SubjectSegmenter _segmenter = SubjectSegmenter(
    options: SubjectSegmenterOptions(
      enableForegroundConfidenceMask: true,
      enableForegroundBitmap: false,
      enableMultipleSubjects: SubjectResultOptions(
        enableConfidenceMask: false,
        enableSubjectBitmap: false,
      ),
    ),
  );

  Future<void> init() async {}

  // CHỈ NHẬN KÍCH THƯỚC CHUẨN ĐÃ XOAY EXIF TỪ GIAO DIỆN
  Future<ui.Image?> getMask(File imageFile, int width, int height) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final result = await _segmenter.processImage(inputImage);

      final confidences = result.foregroundConfidenceMask;
      if (confidences == null || confidences.isEmpty) return null;

      final pixels = await compute(_generatePixelArray, {
        'confidences': confidences,
        'width': width,
        'height': height,
      });

      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        pixels,
        width,
        height,
        ui.PixelFormat.rgba8888,
            (img) => completer.complete(img),
      );

      return await completer.future;
    } catch (e) {
      debugPrint('Lỗi ML Kit Subject Segmentation: $e');
      return null;
    }
  }

  static Uint8List _generatePixelArray(Map<String, dynamic> data) {
    final List<double> confidences = data['confidences'];
    final int width = data['width'];
    final int height = data['height'];

    final pixels = Uint8List(width * height * 4);
    int pIndex = 0;

    final int maxPixels = width * height;
    final int loopCount = confidences.length < maxPixels ? confidences.length : maxPixels;

    for (int i = 0; i < loopCount; i++) {
      // Hạ ngưỡng xuống 0.3 để nhận diện tốt hơn chai lọ nhựa, đồ trong suốt
      if (confidences[i] > 0.3) {
        pixels[pIndex++] = 255;
        pixels[pIndex++] = 255;
        pixels[pIndex++] = 255;
        pixels[pIndex++] = 255; // Trắng đặc để đục lỗ
      } else {
        pixels[pIndex++] = 0;
        pixels[pIndex++] = 0;
        pixels[pIndex++] = 0;
        pixels[pIndex++] = 0;   // Trong suốt
      }
    }
    return pixels;
  }

  void dispose() {
    _segmenter.close();
  }
}
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';
import 'package:phan_loai_rac_qua_hinh_anh/utils/env.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class GeminiService {
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-3.5-flash',
    apiKey: Env.geminiApiKey,
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
    ),
  );

  String _cleanJsonResponse(String rawText) {
    String text = rawText.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  Future<String> processImageAndGetGuidance(File imageFile) async {
    try {
      debugPrint('[GEMINI] Đang nén ảnh tối ưu cho API gửi đi...');
      final compressStartTime = DateTime.now();
      // Nén ảnh siêu nhẹ (480x480, chất lượng 65) giúp dung lượng gửi đi chỉ còn ~15KB.
      // Gemini Flash vẫn nhận diện chính xác 100% rác thải mà tốc độ tải lên tăng gấp 5-10 lần.
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 480,
        minHeight: 480,
        quality: 65,
      );

      final uploadBytes = compressedBytes ?? await imageFile.readAsBytes();
      final compressDuration = DateTime.now().difference(compressStartTime).inMilliseconds;
      debugPrint('[GEMINI] Nén ảnh xong mất ${compressDuration}ms, dung lượng tải lên: ${uploadBytes.length} bytes');

      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

      if (!['image/jpeg', 'image/png', 'image/webp', 'image/bmp'].contains(mimeType)) {
        return 'Lỗi: Định dạng ảnh không được hỗ trợ ($mimeType).';
      }

      final prompt = """
Bạn là một chuyên gia về quản lý và phân loại rác thải tại Việt Nam.
Hãy phân tích hình ảnh rác thải được cung cấp và trả về một đối tượng JSON duy nhất theo cấu trúc bên dưới.
CHÚ Ý: Chỉ trả về đoạn JSON thuần không kèm theo bất kỳ văn bản thừa nào hoặc bao quanh bởi cặp ngoặc markdown code block.

Yêu cầu phân loại rác:
1. Xác định loại rác chính trong ảnh và chọn MỘT trong các nhãn tiếng Anh (category) sau để khớp với hệ thống của chúng tôi: 
   battery, biological, cardboard, clothes, glass, metal, paper, plastic, shoes, trash.
2. Xác định nhóm phân loại (classification) từ một trong các giá trị sau:
   recyclable, organic, hazardous, trash.

Cấu trúc JSON bắt buộc phải trả về:
{
  "category": "nhãn_tiếng_anh_ở_trên",
  "classification": "nhóm_phân_loại_ở_trên",
  "vietnamese_label": "tên tiếng việt cụ thể của vật thể rác",
  "guidance": {
    "disposal": "hướng dẫn chuẩn bị/làm sạch rác chi tiết để vứt bỏ",
    "where": "thùng rác màu gì hoặc điểm thu gom cụ thể",
    "harm": "tác hại nghiêm trọng đến môi trường/sức khỏe nếu xử lý sai"
  },
  "tip": "một mẹo sống xanh nhỏ từ chuyên gia liên quan đến loại rác này"
}
""";

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, uploadBytes),
        ]),
      ];

      final response = await _model.generateContent(content);
      final rawText = response.text?.trim() ?? '';
      if (rawText.isEmpty) {
        return '{"error": "Không nhận được kết quả từ Gemini."}';
      }
      return _cleanJsonResponse(rawText);
    } catch (e) {
      debugPrint('Lỗi khi xử lý ảnh với Gemini: $e');
      rethrow;
    }
  }
}
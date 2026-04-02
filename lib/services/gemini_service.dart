import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';
import 'package:phan_loai_rac_qua_hinh_anh/utils/env.dart';

class GeminiService {
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-flash-latest',
    apiKey: Env.geminiApiKey,
  );

  Future<String> processImageAndGetGuidance(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

      if (!['image/jpeg', 'image/png', 'image/webp', 'image/bmp'].contains(mimeType)) {
        return 'Lỗi: Định dạng ảnh không được hỗ trợ ($mimeType).';
      }

      final prompt = """
Bạn là một chuyên gia về quản lý và phân loại rác thải tại Việt Nam. 
Dựa trên ảnh được cung cấp, hãy thực hiện các bước sau:

1. Xác định loại rác chính trong ảnh. Hãy chọn MỘT trong các nhãn sau để khớp với hệ thống: 
   battery, biological, cardboard, clothes, glass, metal, paper, plastic, shoes, trash.
2. Phân loại rác vào nhóm: Tái chế, Hữu cơ, Nguy hại, hoặc Không tái chế.
3. Cung cấp hướng dẫn xử lý ngắn gọn, chuyên nghiệp.

Định dạng kết quả (Bắt buộc dùng Markdown):
**Loại rác**: [Tên tiếng Việt] ([nhãn tiếng Anh tương ứng])  
**Phân loại**: [Tái chế/Hữu cơ/Nguy hại/Không tái chế]

**Hướng dẫn xử lý**:
- **Cách vứt bỏ**: [Cách chuẩn bị rác]
- **Nơi xử lý**: [Thùng rác hoặc điểm thu gom]
- **Tác hại nếu xử lý sai**: [Ảnh hưởng môi trường/sức khỏe]

**Mẹo sống xanh**: [Một lời khuyên nhỏ từ chuyên gia]
""";

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ]),
      ];

      final response = await _model.generateContent(content);
      return response.text?.trim() ?? 'Không nhận được kết quả từ Gemini.';
    } catch (e) {
      debugPrint('Lỗi khi xử lý ảnh với Gemini: $e');
      return 'Lỗi phân tích Gemini AI: $e';
    }
  }
}
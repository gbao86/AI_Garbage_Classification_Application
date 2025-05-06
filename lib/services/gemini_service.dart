import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';
import 'package:phan_loai_rac_qua_hinh_anh/utils/constants.dart';

class GeminiService {
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash', // Hỗ trợ hình ảnh
    apiKey: Constants.geminiApiKey,
  );

  Future<String> processImageAndGetGuidance(File imageFile) async {
    try {
      // Đọc ảnh dưới dạng bytes
      final imageBytes = await imageFile.readAsBytes();

      // Xác định MIME type
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      if (!['image/jpeg', 'image/png', 'image/webp', 'image/bmp'].contains(mimeType)) {
        return 'Lỗi: Định dạng ảnh không được hỗ trợ ($mimeType).';
      }

      // Tạo prompt
      final prompt = """
Bạn là một chuyên gia về quản lý và phân loại rác thải. Dựa trên ảnh được cung cấp, hãy thực hiện các bước sau bằng tiếng Việt:

1. Xác định loại rác trong ảnh (ví dụ: battery, biological, brown-glass, cardboard, clothes, green-glass, metal, paper, plastic, shoes, trash, white-glass).
2. Phân loại rác (tái chế, hữu cơ, nguy hại, hoặc không tái chế).
3. Cung cấp hướng dẫn chi tiết về cách xử lý loại rác này, bao gồm:
   - Cách vứt bỏ đúng cách (ví dụ: thùng tái chế, điểm thu gom đặc biệt).
   - Nơi xử lý (ví dụ: thùng rác xanh, trung tâm tái chế, bãi chôn lấp).
   - Tác hại nếu xử lý không đúng (ví dụ: ô nhiễm môi trường, ảnh hưởng sức khỏe).
4. Nếu không nhận diện được loại rác, giải thích lý do (ví dụ: ảnh không rõ, không phải rác).

Định dạng kết quả:
**Loại rác**: [loại rác]
**Phân loại**: [tái chế/hữu cơ/nguy hại/không tái chế]
**Hướng dẫn xử lý**:
- [Cách vứt bỏ]
- [Nơi xử lý]
- [Tác hại nếu xử lý sai]
""";

      // Tạo nội dung gửi tới Gemini
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ]),
      ];

      // Gửi yêu cầu
      final response = await _model.generateContent(content);
      final result = response.text?.trim() ?? 'Không nhận được kết quả từ Gemini.';
      return result;
    } catch (e) {
      print('Lỗi khi xử lý ảnh với Gemini: $e');
      return 'Lỗi khi phân loại ảnh với Gemini: $e';
    }
  }
}
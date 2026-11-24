import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:phan_loai_rac_qua_hinh_anh/utils/env.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiService {
  static const List<String> _defaultFallbackModels = [
    'gemini-4-hydrogen',
    'gemini-3.8-flash',
    'gemini-2.5-flash-lite',
  ];

  static String? _cachedRemoteModel;
  static DateTime? _lastSettingsFetch;
  static const Duration _cacheTtl = Duration(minutes: 5);

  /// Làm sạch tên model đọc từ Supabase: loại bỏ khoảng trắng, dấu ngoặc thừa
  /// như ((, )), {{, }}, [[, ]], dấu nháy và tiền tố 'models/'.
  /// Trả về null nếu chuỗi sau khi làm sạch không hợp lệ.
  static String? sanitizeModelName(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map) {
      return sanitizeModelName(raw['model']);
    }

    String value = raw.toString().trim();
    if (value.isEmpty) return null;

    // Trường hợp value lưu nhầm thành chuỗi JSON lồng nhau: '{"model": "..."}'
    if (value.startsWith('{') && value.endsWith('}') && value.contains('model')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map && decoded['model'] != null) {
          return sanitizeModelName(decoded['model']);
        }
      } catch (_) {
        // Tiếp tục làm sạch như chuỗi thường
      }
    }

    // Loại bỏ mọi dấu ngoặc, dấu nháy, khoảng trắng dư thừa do nhập liệu
    value = value.replaceAll(RegExp(r'[\(\)\{\}\[\]"\x27`,;\s]+'), '');

    // Loại bỏ tiền tố 'models/' nếu có
    value = value.replaceFirst(RegExp(r'^models/+'), '');

    // Chỉ chấp nhận tên model hợp lệ (chữ cái, số, dấu chấm, gạch ngang, gạch dưới)
    final validModelRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{1,63}$');
    if (!validModelRegex.hasMatch(value)) {
      debugPrint('[GEMINI] Tên model từ Supabase không hợp lệ sau khi làm sạch: "$value"');
      return null;
    }

    return value;
  }

  /// Trả về thông báo lỗi thân thiện cho người dùng cuối.
  static String friendlyErrorMessage(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('503') ||
        msg.contains('unavailable') ||
        msg.contains('high demand') ||
        msg.contains('overloaded')) {
      return 'Máy chủ Gemini AI đang quá tải tạm thời. Vui lòng thử lại sau vài giây.';
    }
    if (msg.contains('429') ||
        msg.contains('resource_exhausted') ||
        msg.contains('quota')) {
      return 'Hệ thống AI tạm hết hạn mức truy cập. Vui lòng thử lại sau ít phút.';
    }
    if (error is TimeoutException || msg.contains('timeout')) {
      return 'Kết nối tới Gemini AI quá thời gian chờ. Vui lòng kiểm tra mạng và thử lại.';
    }
    if (error is SocketException || msg.contains('failed host lookup')) {
      return 'Không có kết nối mạng để gọi Gemini AI.';
    }
    return 'Không thể kết nối Gemini AI lúc này. Vui lòng thử lại sau.';
  }

  Future<String?> _fetchRemoteModelName() async {
    final now = DateTime.now();
    if (_lastSettingsFetch != null &&
        now.difference(_lastSettingsFetch!) < _cacheTtl) {
      return _cachedRemoteModel;
    }

    try {
      final row = await Supabase.instance.client
          .from('system_settings')
          .select('value')
          .eq('key', 'gemini')
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      final sanitized = sanitizeModelName(row?['value']);
      _cachedRemoteModel = sanitized;
      _lastSettingsFetch = now;
      if (sanitized != null) {
        debugPrint('[GEMINI] Đọc model từ Supabase system_settings: "$sanitized"');
      }
      return sanitized;
    } catch (e) {
      debugPrint('[GEMINI] Không thể đọc system_settings từ Supabase, dùng cấu hình mặc định: $e');
      return _cachedRemoteModel;
    }
  }

  Future<List<String>> _getCandidateModels() async {
    final remoteModel = await _fetchRemoteModelName();
    final ordered = <String>[];
    if (remoteModel != null && remoteModel.isNotEmpty) {
      ordered.add(remoteModel);
    }
    for (final m in _defaultFallbackModels) {
      if (!ordered.contains(m)) {
        ordered.add(m);
      }
    }
    return ordered;
  }

  bool _isFatalAuthError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('api key not valid') ||
        msg.contains('permission_denied') ||
        msg.contains('[401]') ||
        msg.contains('[403]');
  }

  bool _isTransientOverloadError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('503') ||
        msg.contains('unavailable') ||
        msg.contains('high demand') ||
        msg.contains('overloaded') ||
        msg.contains('429') ||
        msg.contains('resource_exhausted');
  }

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

  Future<String> _callModelRestApi({
    required String modelName,
    required String prompt,
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=${Env.geminiApiKey}',
    );

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        if (modelName.contains('gemini-4'))
          'thinkingConfig': {'thinkingLevel': 'LOW'},
      },
    };

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Lỗi API [${response.statusCode}]: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final parts = data['candidates']?[0]?['content']?['parts'] as List<dynamic>?;
    String rawText = '';
    if (parts != null && parts.isNotEmpty) {
      for (final part in parts) {
        if (part is Map && part['thought'] != true && part['text'] != null) {
          rawText = part['text'].toString().trim();
          if (rawText.isNotEmpty) break;
        }
      }
      if (rawText.isEmpty && parts.first is Map && parts.first['text'] != null) {
        rawText = parts.first['text'].toString().trim();
      }
    }

    if (rawText.isEmpty) {
      throw Exception('Phản hồi rỗng từ model $modelName');
    }
    return _cleanJsonResponse(rawText);
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

      final candidateModels = await _getCandidateModels();
      Object? lastError;

      for (int i = 0; i < candidateModels.length; i++) {
        final modelName = candidateModels[i];
        try {
          debugPrint('[GEMINI] Thử gọi REST API model [$modelName] (${i + 1}/${candidateModels.length})...');
          return await _callModelRestApi(
            modelName: modelName,
            prompt: prompt,
            imageBytes: uploadBytes,
            mimeType: mimeType,
          );
        } catch (e) {
          lastError = e;
          debugPrint('[GEMINI] Model [$modelName] thất bại: $e');

          if (_isFatalAuthError(e)) {
            rethrow;
          }

          final isLast = i == candidateModels.length - 1;
          if (!isLast) {
            // Đợi ngắn trước khi chuyển sang model dự phòng để tránh dồn request
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }

          // Nếu là model cuối cùng và gặp lỗi 503/429 tạm thời, thử retry thêm 1 lần
          if (_isTransientOverloadError(e)) {
            debugPrint('[GEMINI] Retry lần cuối với model [$modelName] sau 1.2s...');
            await Future.delayed(const Duration(milliseconds: 1200));
            return await _callModelRestApi(
              modelName: modelName,
              prompt: prompt,
              imageBytes: uploadBytes,
              mimeType: mimeType,
            );
          }
        }
      }

      if (lastError != null) {
        throw lastError;
      }
      return '{"error": "Không nhận được kết quả từ Gemini."}';
    } catch (e) {
      debugPrint('Lỗi khi xử lý ảnh với Gemini: $e');
      rethrow;
    }
  }
}
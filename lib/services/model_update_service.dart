import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Quản lý tải và cập nhật model TFLite từ Supabase Storage.
///
/// ⚠️ QUAN TRỌNG — Điều kiện tải model:
/// Model mặc định trong assets đã được train với 200 epochs / 100.000+ ảnh.
/// Service này CHỈ thay thế model khi phiên bản trên server đạt đủ tiêu chuẩn:
///   - Dataset ≥ [minImageCount] ảnh (mặc định 5000)
///   - Có cột `image_count` trong bảng `model_versions`
///
/// Nếu không đủ điều kiện → chỉ log lịch sử, KHÔNG tải về thay thế.
///
/// Luồng hoạt động:
/// 1. Khi app mở → query bảng `model_versions` lấy phiên bản mới nhất
/// 2. Kiểm tra `image_count` ≥ ngưỡng tối thiểu
/// 3. So sánh `trained_at` với cache local
/// 4. Nếu đủ điều kiện + có model mới → tải về → ưu tiên dùng
/// 5. Fallback về assets nếu chưa có model đạt chuẩn từ server
class ModelUpdateService {
  ModelUpdateService._();
  static final ModelUpdateService instance = ModelUpdateService._();

  static const _prefKeyTrainedAt = 'model_last_trained_at';
  static const _prefKeyModelPath = 'model_local_path';
  static const _prefKeyLabelsPath = 'labels_local_path';

  /// Ngưỡng tối thiểu số ảnh trong dataset để model đủ tin cậy thay thế assets.
  /// Model assets hiện tại: 200 epochs / 100K ảnh → chỉ chấp nhận model mới
  /// nếu dataset ≥ 5000 ảnh (tránh downgrade chất lượng).
  static const int minImageCount = 5000;

  /// Kiểm tra và tải model mới (nếu có VÀ đạt chất lượng). 
  /// Trả về `true` nếu đã cập nhật thành công.
  Future<bool> checkAndUpdate() async {
    try {
      final supabase = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();

      // 1. Query phiên bản mới nhất từ database
      final row = await supabase
          .from('model_versions')
          .select('id, trained_at, model_url, labels_url, image_count')
          .order('trained_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) {
        debugPrint('📦 ModelUpdate: Chưa có model nào trên server.');
        return false;
      }

      final serverTrainedAt = row['trained_at'] as String;
      final imageCount = (row['image_count'] as num?)?.toInt() ?? 0;

      // 2. Kiểm tra ngưỡng chất lượng
      if (imageCount < minImageCount) {
        debugPrint(
          '⏭️ ModelUpdate: Model trên server chỉ có $imageCount ảnh '
          '(cần ≥ $minImageCount). Giữ nguyên model assets.'
        );
        return false;
      }

      // 3. So sánh version — nếu giống thì skip
      final cachedTrainedAt = prefs.getString(_prefKeyTrainedAt);
      if (cachedTrainedAt == serverTrainedAt) {
        debugPrint('✅ ModelUpdate: Model đã là phiên bản mới nhất ($serverTrainedAt).');
        return false;
      }

      debugPrint(
        '🔄 ModelUpdate: Phát hiện model đạt chuẩn mới!\n'
        '   Dataset: $imageCount ảnh | Trained: $serverTrainedAt\n'
        '   Đang tải...'
      );

      final modelUrl = row['model_url'] as String;
      final labelsUrl = row['labels_url'] as String;

      // 4. Tải file song song
      final dir = await getApplicationDocumentsDirectory();
      final modelFile = File('${dir.path}/model_unquant.tflite');
      final labelsFile = File('${dir.path}/labels.txt');

      final results = await Future.wait([
        _downloadFile(modelUrl, modelFile),
        _downloadFile(labelsUrl, labelsFile),
      ]);

      if (results.every((ok) => ok)) {
        // 5. Lưu metadata
        await prefs.setString(_prefKeyTrainedAt, serverTrainedAt);
        await prefs.setString(_prefKeyModelPath, modelFile.path);
        await prefs.setString(_prefKeyLabelsPath, labelsFile.path);

        debugPrint('🎉 ModelUpdate: Đã cập nhật model thành công!');
        debugPrint('   Model: ${modelFile.path} (${modelFile.lengthSync() ~/ 1024} KB)');
        return true;
      }

      return false;
    } catch (e, st) {
      debugPrint('⚠️ ModelUpdate: Lỗi kiểm tra cập nhật: $e\n$st');
      return false;
    }
  }

  /// Đường dẫn model local (nếu đã tải từ server). `null` nếu chưa có.
  Future<String?> get localModelPath async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefKeyModelPath);
    if (path != null && File(path).existsSync()) return path;
    return null;
  }

  /// Đường dẫn labels local (nếu đã tải từ server). `null` nếu chưa có.
  Future<String?> get localLabelsPath async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefKeyLabelsPath);
    if (path != null && File(path).existsSync()) return path;
    return null;
  }

  Future<bool> _downloadFile(String url, File target) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await target.writeAsBytes(response.bodyBytes);
        return true;
      }
      debugPrint('⚠️ ModelUpdate: Tải thất bại (${response.statusCode}): $url');
      return false;
    } catch (e) {
      debugPrint('⚠️ ModelUpdate: Lỗi tải file: $e');
      return false;
    }
  }
}

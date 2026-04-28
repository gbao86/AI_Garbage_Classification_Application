import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Quản lý tải và cập nhật model TFLite từ Supabase Storage.
///
/// Luồng hoạt động:
/// 1. Khi app mở → query bảng `model_versions` lấy phiên bản mới nhất
/// 2. So sánh với `trained_at` đã cache ở local
/// 3. Nếu có model mới → tải về app documents dir → ưu tiên dùng model local
/// 4. Fallback về assets nếu chưa có model nào từ server
class ModelUpdateService {
  ModelUpdateService._();
  static final ModelUpdateService instance = ModelUpdateService._();

  static const _prefKeyTrainedAt = 'model_last_trained_at';
  static const _prefKeyModelPath = 'model_local_path';
  static const _prefKeyLabelsPath = 'labels_local_path';

  /// Kiểm tra và tải model mới (nếu có). Trả về `true` nếu đã cập nhật.
  Future<bool> checkAndUpdate() async {
    try {
      final supabase = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();

      // 1. Query phiên bản mới nhất từ database
      final row = await supabase
          .from('model_versions')
          .select('id, trained_at, model_url, labels_url')
          .order('trained_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) {
        debugPrint('📦 ModelUpdate: Chưa có model nào trên server.');
        return false;
      }

      final serverTrainedAt = row['trained_at'] as String;
      final cachedTrainedAt = prefs.getString(_prefKeyTrainedAt);

      // 2. So sánh — nếu giống nhau thì skip
      if (cachedTrainedAt == serverTrainedAt) {
        debugPrint('✅ ModelUpdate: Model đã là phiên bản mới nhất ($serverTrainedAt).');
        return false;
      }

      debugPrint('🔄 ModelUpdate: Phát hiện model mới ($serverTrainedAt). Đang tải...');

      final modelUrl = row['model_url'] as String;
      final labelsUrl = row['labels_url'] as String;

      // 3. Tải file song song
      final dir = await getApplicationDocumentsDirectory();
      final modelFile = File('${dir.path}/model_unquant.tflite');
      final labelsFile = File('${dir.path}/labels.txt');

      final results = await Future.wait([
        _downloadFile(modelUrl, modelFile),
        _downloadFile(labelsUrl, labelsFile),
      ]);

      if (results.every((ok) => ok)) {
        // 4. Lưu metadata
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

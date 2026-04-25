import 'dart:io';

void main() async {
  final envFile = File('.env');
  final configFile = File('web_admin/js/config.js');

  if (!await envFile.exists()) {
    print('❌ Error: File .env không tồn tại!');
    return;
  }

  final lines = await envFile.readAsLines();
  String? url;
  String? key;

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final part = line.split('#')[0].trim();
    if (!part.contains('=')) continue;

    final keyName = part.split('=')[0].trim();
    final value = part.split('=')[1].trim().replaceAll('"', '').replaceAll("'", "");

    if (keyName == 'SUPABASE_URL') {
      url = value;
    } 
    // Ưu tiên lấy Publishable Key nếu tìm thấy
    else if (keyName == 'SUPABASE_PUBLISHABLE_KEY') {
      key = value;
    } 
    // Chỉ lấy Anon Key nếu chưa tìm thấy Publishable Key trước đó
    else if (keyName == 'SUPABASE_ANON_KEY' && key == null) {
      key = value;
    }
  }

  if (url == null || key == null) {
    print('❌ Error: Thiếu SUPABASE_URL hoặc Key trong .env');
    return;
  }

  final configContent = '''
// TỰ ĐỘNG SINH RA BỞI SCRIPTS/SYNC_ENV.DART - KHÔNG SỬA TAY
export function getSupabaseConfig() {
    return {
        url: "$url",
        key: "$key"
    };
}
''';

  await configFile.writeAsString(configContent);
  print('✅ Đã đồng bộ cấu hình sang web_admin/js/config.js');
  // Đã sửa lỗi cú pháp bằng cách dùng dấu nháy kép bên ngoài
  print("📍 Key đang dùng: ${key.startsWith('sb_') ? 'Publishable Key' : 'Anon JWT'}");
}

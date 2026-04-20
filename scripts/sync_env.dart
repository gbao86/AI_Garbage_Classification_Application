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
    // Bỏ qua dòng trống hoặc bắt đầu bằng dấu #
    if (line.isEmpty || line.startsWith('#')) continue;

    // Tách bỏ comment nằm cùng dòng (nếu có)
    final part = line.split('#')[0].trim();
    if (!part.contains('=')) continue;

    final keyName = part.split('=')[0].trim();
    final value = part.split('=')[1].trim().replaceAll('"', '').replaceAll("'", "");

    if (keyName == 'SUPABASE_URL') {
      url = value;
    } else if (keyName == 'SUPABASE_ANON_KEY') {
      key = value;
    }
  }

  if (url == null || key == null) {
    print('❌ Error: Thiếu SUPABASE_URL hoặc SUPABASE_ANON_KEY trong .env');
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
  print('✅ Đã đồng bộ .env sang web_admin/js/config.js');
  print('📍 URL: $url');
  print('📍 Key (10 ký tự): \${key.substring(0, 10)}...');
}

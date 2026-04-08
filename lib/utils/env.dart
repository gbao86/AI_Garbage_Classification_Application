import 'package:envied/envied.dart';

part 'env.g.dart';

/// Giá trị được nhúng lúc build. Sau khi đổi file [.env], chạy:
/// `dart run build_runner build --delete-conflicting-outputs`
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'GEMINI_API_KEY', obfuscate: true)
  static final String geminiApiKey = _Env.geminiApiKey;

  @EnviedField(varName: 'SUPABASE_URL')
  static final String supabaseUrl = _Env.supabaseUrl;

  /// Khóa Publishable mới (`sb_publishable_...`) hoặc legacy anon JWT — dùng cho [Supabase.initialize] `anonKey`.
  @EnviedField(varName: 'SUPABASE_PUBLISHABLE_KEY', obfuscate: true)
  static final String supabasePublishableKey = _Env.supabasePublishableKey;

  /// OAuth 2.0 **Web client** ID (`*.apps.googleusercontent.com`) — bắt buộc để lấy `idToken` trên Android/iOS.
  /// Trùng với Client ID khi bật Google provider trên Supabase (và trong Firebase / Google Cloud).
  @EnviedField(varName: 'GOOGLE_WEB_CLIENT_ID')
  static final String googleWebClientId = _Env.googleWebClientId;
}

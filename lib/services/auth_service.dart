import 'package:google_sign_in/google_sign_in.dart';
import 'package:phan_loai_rac_qua_hinh_anh/utils/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Đăng nhập Supabase Auth + truy vấn bảng [profiles] (RLS).
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static Future<void>? _googleInitFuture;

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  Session? get currentSession => client.auth.currentSession;

  Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) {
    return client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: 'io.supabase.ecosort://login-callback',
      data: displayName != null && displayName.trim().isNotEmpty
          ? {'display_name': displayName.trim(), 'full_name': displayName.trim()}
          : null,
    );
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await client.auth.signOut();
  }

  Future<void> _ensureGoogleSignInReady(String webClientId) async {
    _googleInitFuture ??= GoogleSignIn.instance.initialize(serverClientId: webClientId);
    await _googleInitFuture;
  }

  /// Đăng nhập Google (native) → Supabase [signInWithIdToken].
  /// Trả về `null` nếu người dùng đóng hộp thoại Google.
  /// Cần [Env.googleWebClientId] và Google provider đã bật trên Supabase.
  Future<AuthResponse?> signInWithGoogle() async {
    final webId = Env.googleWebClientId.trim();
    if (webId.isEmpty) {
      throw Exception('Chưa cấu hình GOOGLE_WEB_CLIENT_ID trong .env');
    }

    await _ensureGoogleSignInReady(webId);

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile', 'openid'],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted ||
          e.code == GoogleSignInExceptionCode.uiUnavailable) {
        return null;
      }
      rethrow;
    }

    final tokens = account.authentication;
    final idToken = tokens.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Không lấy được idToken. Kiểm tra GOOGLE_WEB_CLIENT_ID (Web client), SHA-1 Android và URL scheme iOS.',
      );
    }

    String? accessToken;
    try {
      final authz = await account.authorizationClient.authorizationForScopes(
        const ['email', 'profile', 'openid'],
      );
      accessToken = authz?.accessToken;
    } catch (_) {}

    final res = await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final u = res.session?.user;
    if (u != null) {
      final meta = u.userMetadata;
      final dn = meta?['full_name'] as String? ?? meta?['name'] as String?;
      final pic = meta?['avatar_url'] as String? ?? meta?['picture'] as String?;
      if ((dn != null && dn.isNotEmpty) || (pic != null && pic.isNotEmpty)) {
        try {
          await client.from('profiles').update({
            if (dn != null && dn.isNotEmpty) 'display_name': dn,
            if (pic != null && pic.isNotEmpty) 'avatar_url': pic,
          }).eq('id', u.id);
        } catch (_) {
          // Hàng profiles có thể chưa kịp tạo từ trigger auth.users
        }
      }
    }

    return res;
  }

  /// Một dòng profile theo schema migration (bảng public.profiles).
  Future<Map<String, dynamic>?> fetchMyProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    return client.from('profiles').select().eq('id', uid).maybeSingle();
  }
}

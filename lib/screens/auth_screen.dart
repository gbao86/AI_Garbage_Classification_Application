import 'package:flutter/material.dart';
import 'package:phan_loai_rac_qua_hinh_anh/utils/env.dart';
import 'package:phan_loai_rac_qua_hinh_anh/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _auth = AuthService.instance;

  bool _registerMode = false;
  bool _loading = false;
  bool _obscure = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Design tokens ────────────────────────────────────────────────────────
  static const _green900 = Color(0xFF1B4332);
  static const _green700 = Color(0xFF2D6A4F);
  static const _green500 = Color(0xFF40916C);
  static const _green300 = Color(0xFF74C69D);
  static const _green100 = Color(0xFFD8F3DC);
  static const _green50  = Color(0xFFF0FAF2);
  static const _surface  = Color(0xFFFFFFFF);
  static const _textPrimary   = Color(0xFF1A2E1C);
  static const _textSecondary = Color(0xFF52735A);
  static const _border = Color(0xFFB7DFC5);
  static const _errorRed = Color(0xFFD62839);
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _fadeCtrl.reset();
    setState(() => _registerMode = !_registerMode);
    _fadeCtrl.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_registerMode) {
        final res = await _auth.signUpWithEmail(
          email: _email.text,
          password: _password.text,
          displayName: _displayName.text,
        );
        if (!mounted) return;
        if (res.session != null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(
            'Đã tạo tài khoản. Kiểm tra email xác nhận (nếu bật) rồi đăng nhập.',
            isError: false,
          ),
        );
        _toggleMode();
      } else {
        await _auth.signInWithEmail(
            email: _email.text, password: _password.text);
      }
    } catch (e) {
      if (mounted) {
        final msg =
        e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
        ScaffoldMessenger.of(context)
            .showSnackBar(_buildSnackBar(msg, isError: true));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    if (Env.googleWebClientId.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          'Thiếu GOOGLE_WEB_CLIENT_ID trong .env — chạy build_runner sau khi thêm.',
          isError: true,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _auth.signInWithGoogle();
      if (!mounted) return;
      if (res == null) return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_buildSnackBar('$e', isError: true));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  SnackBar _buildSnackBar(String message, {required bool isError}) {
    return SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
      backgroundColor: isError ? _errorRed : _green700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 600;

    return Scaffold(
      backgroundColor: _green50,
      body: Stack(
        children: [
          // ── Decorative background blobs ──────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _GreenBlob(size: 260, color: _green100),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _GreenBlob(size: 300, color: _green100),
          ),
          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.25 : 24,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 36),
                      _buildCard(),
                      const SizedBox(height: 20),
                      _buildToggleButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo badge
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _green700,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _green700.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, size: 44, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'EcoSort by Bao',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _green900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _registerMode ? 'Tạo tài khoản mới' : 'Chào mừng trở lại',
          style: const TextStyle(
            fontSize: 15,
            color: _textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── Card ─────────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: _green900.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Tab indicator ────────────────────────────────────────────
            _buildTabIndicator(),
            const SizedBox(height: 24),

            // ── Fields ───────────────────────────────────────────────────
            if (_registerMode) ...[
              _buildField(
                controller: _displayName,
                label: 'Tên hiển thị',
                icon: Icons.person_outline_rounded,
                action: TextInputAction.next,
              ),
              const SizedBox(height: 14),
            ],
            _buildField(
              controller: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              action: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                if (!v.contains('@')) return 'Email không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildPasswordField(),

            const SizedBox(height: 24),

            // ── Primary button ───────────────────────────────────────────
            _buildPrimaryButton(),

            const SizedBox(height: 20),

            // ── Divider ──────────────────────────────────────────────────
            _buildDivider(),

            const SizedBox(height: 20),

            // ── Google button ────────────────────────────────────────────
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  // ── Tab indicator ────────────────────────────────────────────────────────
  Widget _buildTabIndicator() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _green50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Đăng nhập',
            selected: !_registerMode,
            onTap: _registerMode ? _toggleMode : null,
          ),
          _TabItem(
            label: 'Đăng ký',
            selected: _registerMode,
            onTap: !_registerMode ? _toggleMode : null,
          ),
        ],
      ),
    );
  }

  // ── Generic text field ───────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    String? Function(String?)? validator,
    bool autocorrect = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      textInputAction: action,
      style: const TextStyle(fontSize: 15, color: _textPrimary),
      validator: validator,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  // ── Password field ───────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _password,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      style: const TextStyle(fontSize: 15, color: _textPrimary),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
        if (_registerMode && v.length < 6) return 'Tối thiểu 6 ký tự';
        return null;
      },
      decoration: _inputDecoration(
        label: 'Mật khẩu',
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: _textSecondary,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14, color: _textSecondary),
      floatingLabelStyle:
      const TextStyle(fontSize: 13, color: _green700, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, size: 20, color: _textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: _green50,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _border.withOpacity(0.8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _green500, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorRed, width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 12, color: _errorRed),
    );
  }

  // ── Primary CTA ──────────────────────────────────────────────────────────
  Widget _buildPrimaryButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _green300,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        child: _loading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _registerMode
                  ? Icons.person_add_outlined
                  : Icons.login_rounded,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(_registerMode ? 'Tạo tài khoản' : 'Đăng nhập'),
          ],
        ),
      ),
    );
  }

  // ── Divider ──────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
            child: Divider(color: _border.withOpacity(0.7), thickness: 0.8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'hoặc tiếp tục với',
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(
            child: Divider(color: _border.withOpacity(0.7), thickness: 0.8)),
      ],
    );
  }

  // ── Google button ────────────────────────────────────────────────────────
  Widget _buildGoogleButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: _loading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: BorderSide(color: _border.withOpacity(0.9)),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Official Google logo SVG
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 10),
            Text(_registerMode ? 'Đăng ký bằng Google' : 'Tiếp tục với Google'),
          ],
        ),
      ),
    );
  }

  // ── Mode toggle ──────────────────────────────────────────────────────────
  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _registerMode ? 'Đã có tài khoản?' : 'Chưa có tài khoản?',
          style: const TextStyle(fontSize: 14, color: _textSecondary),
        ),
        TextButton(
          onPressed: _loading ? null : _toggleMode,
          style: TextButton.styleFrom(
            foregroundColor: _green700,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(_registerMode ? 'Đăng nhập' : 'Đăng ký ngay'),
        ),
      ],
    );
  }
}

// ── Tab item ─────────────────────────────────────────────────────────────────
class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  static const _green700 = Color(0xFF2D6A4F);
  static const _textSecondary = Color(0xFF52735A);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? _green700 : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
              BoxShadow(
                color: _green700.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : [],
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : _textSecondary,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// ── Official Google logo painter ─────────────────────────────────────────────
// Path data ported from the official Google "G" SVG (google.com/images/branding)
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 20.0; // scale factor (designed on 20×20)

    // Blue (#4285F4) — right arc & top
    final blue = Paint()..color = const Color(0xFF4285F4);
    // Red (#EA4335) — top-left
    final red  = Paint()..color = const Color(0xFFEA4335);
    // Yellow (#FBBC05) — bottom-left
    final yel  = Paint()..color = const Color(0xFFFBBC05);
    // Green (#34A853) — bottom
    final grn  = Paint()..color = const Color(0xFF34A853);

    // ── White background circle ───────────────────────────────────────────
    canvas.drawCircle(
      Offset(10 * s, 10 * s),
      10 * s,
      Paint()..color = Colors.white,
    );

    // ── Green — bottom-right arc (6 o'clock → 3 o'clock) ────────────────
    final greenPath = Path()
      ..moveTo(10 * s, 10 * s)
      ..arcTo(
        Rect.fromCircle(center: Offset(10 * s, 10 * s), radius: 7.5 * s),
        0.35, 1.25, false,
      )
      ..close();
    canvas.drawPath(greenPath, grn);

    // ── Yellow — bottom-left arc ──────────────────────────────────────────
    final yelPath = Path()
      ..moveTo(10 * s, 10 * s)
      ..arcTo(
        Rect.fromCircle(center: Offset(10 * s, 10 * s), radius: 7.5 * s),
        1.6, 1.2, false,
      )
      ..close();
    canvas.drawPath(yelPath, yel);

    // ── Red — top-left arc ────────────────────────────────────────────────
    final redPath = Path()
      ..moveTo(10 * s, 10 * s)
      ..arcTo(
        Rect.fromCircle(center: Offset(10 * s, 10 * s), radius: 7.5 * s),
        2.8, 1.25, false,
      )
      ..close();
    canvas.drawPath(redPath, red);

    // ── Blue — top-right arc ──────────────────────────────────────────────
    final bluePath = Path()
      ..moveTo(10 * s, 10 * s)
      ..arcTo(
        Rect.fromCircle(center: Offset(10 * s, 10 * s), radius: 7.5 * s),
        4.05, 1.52, false,
      )
      ..close();
    canvas.drawPath(bluePath, blue);

    // ── White inner circle (donut hole) ───────────────────────────────────
    canvas.drawCircle(
      Offset(10 * s, 10 * s),
      4.8 * s,
      Paint()..color = Colors.white,
    );

    // ── Blue horizontal bar (the crossbar of the "G") ─────────────────────
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10 * s, 8.8 * s, 7.4 * s, 2.4 * s),
      const Radius.circular(1),
    );
    canvas.drawRRect(barRect, blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Decorative blob ───────────────────────────────────────────────────────────
class _GreenBlob extends StatelessWidget {
  const _GreenBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/auth_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Chuyển giữa [AuthScreen] và [HomeScreen] theo phiên đăng nhập Supabase.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

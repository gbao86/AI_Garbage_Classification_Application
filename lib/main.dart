import 'package:flutter/material.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/home_screen2.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/about_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phân Loại Rác AI',
      theme: AppTheme.lightTheme,
      home: HomeScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/about': (context) => AboutScreen(),
      },
    );
  }
}
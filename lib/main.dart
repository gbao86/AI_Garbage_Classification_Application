import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phan_loai_rac_qua_hinh_anh/features/game/game_provider.dart';
import 'package:phan_loai_rac_qua_hinh_anh/features/game/game_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/features/game/badge_inventory_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/home_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/about_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/map_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EcoSort by Bao',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/about': (context) => const AboutScreen(),
          '/map': (context) => const MapScreen(),
          '/game': (context) => const GameScreen(),
          '/badges': (context) => const BadgeInventoryScreen(),
        },
      ),
    );
  }
}

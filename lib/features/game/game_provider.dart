import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameProvider with ChangeNotifier {
  int _score = 0;
  List<String> _earnedBadges = [];
  
  int get score => _score;
  List<String> get earnedBadges => _earnedBadges;

  GameProvider() {
    _loadData();
  }

  // Huy hiệu giả lập
  final Map<String, int> availableBadges = {
    'Mầm Xanh': 50,
    'Chiến binh Eco': 150,
    'Đại sứ Môi trường': 500,
    'Bậc thầy Phân loại': 1000,
  };

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _score = prefs.getInt('user_score') ?? 0;
    _earnedBadges = prefs.getStringList('user_badges') ?? [];
    notifyListeners();
  }

  Future<void> addScore(int points) async {
    _score += points;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_score', _score);
    notifyListeners();
  }

  bool canRedeem(int cost) => _score >= cost;

  Future<bool> redeemBadge(String badgeName, int cost) async {
    if (canRedeem(cost) && !_earnedBadges.contains(badgeName)) {
      _score -= cost;
      _earnedBadges.add(badgeName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_score', _score);
      await prefs.setStringList('user_badges', _earnedBadges);
      notifyListeners();
      return true;
    }
    return false;
  }
}

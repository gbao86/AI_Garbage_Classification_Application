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

  final Map<String, String> badgeIcons = {
    'Mầm Xanh': '🌱',
    'Chiến binh Eco': '🛡️',
    'Đại sứ Môi trường': '🏅',
    'Bậc thầy Phân loại': '👑',
  };

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _score = prefs.getInt('user_score') ?? 0;
    _earnedBadges = prefs.getStringList('user_badges') ?? [];
    await _syncBadgesByScore();
    notifyListeners();
  }

  Future<void> addScore(int points) async {
    if (points <= 0) return;
    _score += points;
    await _syncBadgesByScore();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_score', _score);
    notifyListeners();
  }

  Future<void> _syncBadgesByScore() async {
    bool changed = false;
    for (final entry in availableBadges.entries) {
      if (_score >= entry.value && !_earnedBadges.contains(entry.key)) {
        _earnedBadges.add(entry.key);
        changed = true;
      }
    }

    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_badges', _earnedBadges);
    }
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Đồng bộ điểm / huy hiệu từ Supabase ([profiles], [user_badges]) khi đã đăng nhập.
  Future<void> syncFromSupabase() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      await _loadData();
      return;
    }
    try {
      final profile = await Supabase.instance.client.from('profiles').select('xp_total').eq('id', uid).maybeSingle();
      if (profile != null) {
        _score = (profile['xp_total'] as num?)?.toInt() ?? _score;
      }
    } catch (e, st) {
      debugPrint('syncFromSupabase profile: $e\n$st');
    }

    try {
      final badgeRows = await Supabase.instance.client.from('user_badges').select('badges(name_vi)').eq('user_id', uid);

      final names = <String>[];
      for (final row in badgeRows) {
        final b = row['badges'];
        if (b is Map && b['name_vi'] != null) {
          names.add(b['name_vi'] as String);
        }
      }
      if (names.isNotEmpty) {
        _earnedBadges = names;
      }
    } catch (e, st) {
      debugPrint('syncFromSupabase badges: $e\n$st');
    }

    try {
      await _syncBadgesByScore();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_score', _score);
      await prefs.setStringList('user_badges', _earnedBadges);
      notifyListeners();
    } catch (e, st) {
      debugPrint('syncFromSupabase persist: $e\n$st');
      await _loadData();
    }
  }

  Future<void> addScore(int points) async {
    if (points <= 0) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final res = await Supabase.instance.client.rpc(
          'rpc_award_points',
          params: {
            'p_delta': points,
            'p_reason': 'game_session',
            'p_ref_type': 'game',
            'p_metadata': <String, dynamic>{},
          },
        );
        if (res != null) {
          _score = int.tryParse(res.toString()) ?? _score;
        } else {
          _score += points;
        }
        await _syncBadgesByScore();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_score', _score);
        await prefs.setStringList('user_badges', _earnedBadges);
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('rpc_award_points fallback local: $e');
      }
    }
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
    if (!canRedeem(cost) || _earnedBadges.contains(badgeName)) return false;

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final res = await Supabase.instance.client.rpc(
          'rpc_award_points',
          params: {
            'p_delta': -cost,
            'p_reason': 'badge_redeem',
            'p_ref_type': 'badge',
            'p_metadata': <String, dynamic>{'badge_name': badgeName},
          },
        );
        if (res != null) {
          _score = int.tryParse(res.toString()) ?? _score;
        } else {
          _score -= cost;
        }
        _earnedBadges.add(badgeName);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_score', _score);
        await prefs.setStringList('user_badges', _earnedBadges);
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('redeemBadge rpc fallback: $e');
      }
    }

    _score -= cost;
    _earnedBadges.add(badgeName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_score', _score);
    await prefs.setStringList('user_badges', _earnedBadges);
    notifyListeners();
    return true;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameProvider with ChangeNotifier {
  int _score = 0;
  List<String> _earnedBadges = [];
  int _streak = 0;
  List<Map<String, dynamic>> _dailyQuests = [];
  
  int get score => _score;
  List<String> get earnedBadges => _earnedBadges;
  int get streak => _streak;
  List<Map<String, dynamic>> get dailyQuests => _dailyQuests;

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
    _streak = prefs.getInt('user_streak') ?? 0;
    await _syncBadgesByScore();
    notifyListeners();
  }

  /// Đồng bộ điểm / huy hiệu / streak / nhiệm vụ từ Supabase
  Future<void> syncFromSupabase() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      await _loadData();
      return;
    }
    
    // 1. Đồng bộ XP và Streak
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('xp_total, current_streak')
          .eq('id', uid)
          .maybeSingle();
      if (profile != null) {
        _score = (profile['xp_total'] as num?)?.toInt() ?? _score;
        _streak = (profile['current_streak'] as num?)?.toInt() ?? _streak;
      }
    } catch (e, st) {
      debugPrint('syncFromSupabase profile error: $e\n$st');
    }

    // 2. Đồng bộ Huy hiệu
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
      debugPrint('syncFromSupabase badges error: $e\n$st');
    }

    // 3. Đồng bộ Nhiệm vụ hằng ngày
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      
      final activeQuests = await Supabase.instance.client
          .from('quests')
          .select()
          .eq('is_active', true);
      
      final userQuests = await Supabase.instance.client
          .from('user_quests')
          .select()
          .eq('user_id', uid)
          .eq('date', todayStr);

      final List<Map<String, dynamic>> mergedQuests = [];
      for (var q in activeQuests) {
        final qId = q['id'];
        Map<String, dynamic>? userQ;
        for (final uq in userQuests) {
          if (uq['quest_id'] == qId) {
            userQ = uq;
            break;
          }
        }

        mergedQuests.add({
          'id': qId,
          'title_vi': q['title_vi'],
          'description': q['description'],
          'quest_type': q['quest_type'],
          'target_count': q['target_count'] as int,
          'reward_xp': q['reward_xp'] as int,
          'progress_count': userQ != null ? userQ['progress_count'] as int : 0,
          'is_completed': userQ != null ? userQ['is_completed'] as bool : false,
        });
      }
      _dailyQuests = mergedQuests;
    } catch (e, st) {
      debugPrint('syncFromSupabase quests error: $e\n$st');
    }

    try {
      await _syncBadgesByScore();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_score', _score);
      await prefs.setStringList('user_badges', _earnedBadges);
      await prefs.setInt('user_streak', _streak);
      notifyListeners();
    } catch (e, st) {
      debugPrint('syncFromSupabase persist error: $e\n$st');
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

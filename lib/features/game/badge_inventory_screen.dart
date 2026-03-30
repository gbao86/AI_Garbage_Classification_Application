import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_provider.dart';

class BadgeInventoryScreen extends StatelessWidget {
  const BadgeInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final orderedBadges = game.availableBadges.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final nextBadge = orderedBadges.cast<MapEntry<String, int>?>().firstWhere(
          (entry) => !game.earnedBadges.contains(entry!.key),
          orElse: () => null,
        );

    final currentScore = game.score;
    final prevThreshold = _getPreviousThreshold(currentScore, orderedBadges);
    final nextThreshold = nextBadge?.value ?? prevThreshold;
    final progress = nextBadge == null
        ? 1.0
        : ((currentScore - prevThreshold) / (nextThreshold - prevThreshold)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho huy hiệu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildOverviewCard(
            context,
            currentScore: currentScore,
            earnedCount: game.earnedBadges.length,
            totalCount: orderedBadges.length,
          ),
          const SizedBox(height: 16),
          _buildProgressCard(
            context,
            progress: progress,
            nextBadgeName: nextBadge?.key,
            nextBadgeScore: nextBadge?.value,
            currentScore: currentScore,
          ),
          const SizedBox(height: 20),
          Text(
            'Danh sách huy hiệu',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...orderedBadges.map((entry) {
            final unlocked = game.earnedBadges.contains(entry.key);
            final icon = game.badgeIcons[entry.key] ?? '🏅';
            return _buildBadgeTile(
              context,
              icon: icon,
              name: entry.key,
              targetScore: entry.value,
              currentScore: currentScore,
              unlocked: unlocked,
            );
          }),
        ],
      ),
    );
  }

  int _getPreviousThreshold(int currentScore, List<MapEntry<String, int>> badges) {
    int prev = 0;
    for (final b in badges) {
      if (b.value <= currentScore) {
        prev = b.value;
      } else {
        break;
      }
    }
    return prev;
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required int currentScore,
    required int earnedCount,
    required int totalCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Điểm hiện tại: $currentScore',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã mở $earnedCount / $totalCount huy hiệu',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context, {
    required double progress,
    required String? nextBadgeName,
    required int? nextBadgeScore,
    required int currentScore,
  }) {
    final doneAll = nextBadgeName == null;
    final need = doneAll ? 0 : (nextBadgeScore! - currentScore).clamp(0, 1 << 30);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doneAll ? 'Bạn đã mở tất cả huy hiệu' : 'Huy hiệu kế tiếp: $nextBadgeName',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (!doneAll)
            Text(
              'Cần thêm $need điểm để mở khóa',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            )
          else
            Text(
              'Tiếp tục chơi để duy trì phong độ!',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeTile(
    BuildContext context, {
    required String icon,
    required String name,
    required int targetScore,
    required int currentScore,
    required bool unlocked,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? Colors.green.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: unlocked ? Colors.green.withValues(alpha: 0.14) : Colors.grey.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'Mốc mở khóa: $targetScore điểm',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: unlocked ? Colors.green.withValues(alpha: 0.14) : Colors.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              unlocked ? 'Đã mở' : '${(targetScore - currentScore).clamp(0, 1 << 30)} điểm nữa',
              style: TextStyle(
                color: unlocked ? Colors.green.shade800 : Colors.orange.shade900,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

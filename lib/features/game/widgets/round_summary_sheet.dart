import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game_question.dart';

class QuestionAttemptResult {
  final GameQuestion question;
  final bool isCorrect;
  final WasteCategory? selectedCategory;

  QuestionAttemptResult({
    required this.question,
    required this.isCorrect,
    this.selectedCategory,
  });
}

class RoundSummarySheet extends StatelessWidget {
  final int round;
  final int roundScore;
  final int totalQuestions;
  final int correctCount;
  final int maxStreak;
  final List<QuestionAttemptResult> attempts;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const RoundSummarySheet({
    super.key,
    required this.round,
    required this.roundScore,
    required this.totalQuestions,
    required this.correctCount,
    required this.maxStreak,
    required this.attempts,
    required this.onPlayAgain,
    required this.onExit,
  });

  String _getCategoryName(WasteCategory category) {
    switch (category) {
      case WasteCategory.recyclable:
        return 'Tái chế';
      case WasteCategory.organic:
        return 'Hữu cơ';
      case WasteCategory.hazardous:
        return 'Nguy hại';
      case WasteCategory.trash:
        return 'Rác khác';
    }
  }

  Color _getCategoryColor(WasteCategory category) {
    switch (category) {
      case WasteCategory.recyclable:
        return const Color(0xFF0284C7);
      case WasteCategory.organic:
        return const Color(0xFF16A34A);
      case WasteCategory.hazardous:
        return const Color(0xFFE11D48);
      case WasteCategory.trash:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accuracyPercent = totalQuestions > 0
        ? ((correctCount / totalQuestions) * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoàn thành Vòng $round! 🎉',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tổng kết kết quả & Sổ tay kiến thức xanh',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                    : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Điểm đạt', '+$roundScore XP', const Color(0xFF10B981)),
                _buildDivider(isDark),
                _buildStatColumn('Chính xác', '$correctCount/$totalQuestions ($accuracyPercent%)',
                    accuracyPercent >= 70 ? const Color(0xFF10B981) : Colors.orange),
                _buildDivider(isDark),
                _buildStatColumn('Max Streak', '🔥 x$maxStreak', Colors.deepOrange),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Title for Fun Facts Logbook
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(
                'Sổ tay Kiến thức Xanh (${attempts.length} món)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Scrollable List of Items with Fun Facts
          Expanded(
            child: attempts.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có dữ liệu vòng chơi',
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: attempts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = attempts[index];
                      final q = item.question;
                      final catColor = _getCategoryColor(q.correctCategory);
                      final catName = _getCategoryName(q.correctCategory);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isCorrect
                                ? Colors.green.withValues(alpha: 0.35)
                                : Colors.red.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: CachedNetworkImage(
                                  imageUrl: q.imagePath,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image, size: 24),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Info & Fun fact
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          q.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: catColor.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          catName,
                                          style: TextStyle(
                                            color: catColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (q.funFact.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('💡 ', style: TextStyle(fontSize: 12)),
                                        Expanded(
                                          child: Text(
                                            q.funFact,
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 1.35,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: onExit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Thoát ra', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onPlayAgain,
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('Tiếp tục vòng mới 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 26,
      width: 1,
      color: isDark ? Colors.white12 : Colors.grey.shade300,
    );
  }
}

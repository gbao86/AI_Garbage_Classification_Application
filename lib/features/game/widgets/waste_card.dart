import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game_question.dart';

class WasteCard extends StatelessWidget {
  final GameQuestion question;
  final bool isDragging;
  final bool showHint;
  final VoidCallback? onToggleHint;

  const WasteCard({
    super.key,
    required this.question,
    this.isDragging = false,
    this.showHint = false,
    this.onToggleHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDragging ? theme.colorScheme.primary : borderColor,
          width: isDragging ? 2.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDragging
                ? (isDark ? Colors.black54 : Colors.black26)
                : (isDark ? Colors.black38 : const Color(0x0F000000)),
            blurRadius: isDragging ? 28 : 16,
            offset: isDragging ? const Offset(0, 16) : const Offset(0, 6),
            spreadRadius: isDragging ? 2 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Container (Top hero area)
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Waste Image
                  CachedNetworkImage(
                    imageUrl: question.imagePath,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) => Container(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      child: const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_rounded,
                              size: 48,
                              color: subtextColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ảnh không khả dụng',
                              style: TextStyle(
                                fontSize: 11,
                                color: subtextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top Dark Gradient Overlay for Badges
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top Left Badge: Target indicator
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.ads_click_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'BẤM CHỌN NHÓM ĐÚNG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top Right: Hint Toggle Button
                  if (onToggleHint != null && question.funFact.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onToggleHint,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: showHint
                                  ? Colors.amber.shade400
                                  : Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: showHint
                                    ? Colors.amber.shade600
                                    : Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lightbulb_rounded,
                                  size: 14,
                                  color: showHint ? Colors.black87 : Colors.amberAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  showHint ? 'Ẩn mẹo' : 'Gợi ý',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: showHint ? Colors.black87 : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Bottom gradient overlay for image separation
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            cardBg.withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Hint Overlay (If user toggled hint)
                  if (showHint)
                    Positioned.fill(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.black.withValues(alpha: 0.82),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lightbulb_outline_rounded,
                                    color: Colors.amberAccent, size: 32),
                                const SizedBox(height: 8),
                                const Text(
                                  'Gợi ý & Kiến thức:',
                                  style: TextStyle(
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  question.funFact,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Card Bottom Details Area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    question.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 14, color: subtextColor),
                      const SizedBox(width: 4),
                      Text(
                        'Bấm chọn 1 trong 4 nhóm bên dưới 👇',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

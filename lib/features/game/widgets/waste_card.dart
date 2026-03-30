import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game_question.dart';

class WasteCard extends StatelessWidget {
  final GameQuestion question;

  const WasteCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.clamp(240.0, 420.0);
        final borderRadius = (cardWidth * 0.08).clamp(16.0, 28.0);
        final titleSize = (cardWidth * 0.07).clamp(16.0, 24.0);
        final subtitleSize = (cardWidth * 0.038).clamp(11.0, 14.0);

        return Center(
          child: SizedBox(
            width: cardWidth,
            child: AspectRatio(
              aspectRatio: 0.97,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: question.imagePath,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey),
                                ),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.28),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.04),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                question.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: cardWidth * 0.018),
                              Text(
                                'Quan sát kỹ hình ảnh trước khi chọn đáp án',
                                style: TextStyle(fontSize: subtitleSize, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

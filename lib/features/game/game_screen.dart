import 'package:flutter/material.dart';
import 'package:provider/package:provider.dart';
import 'package:lottie/lottie.dart';
import 'game_provider.dart';
import 'models/game_question.dart';
import 'widgets/waste_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _AboutGameScreenState extends State<GameScreen> {
  final List<GameQuestion> _questions = [
    GameQuestion(
      name: 'Vỏ chai nhựa',
      imagePath: 'assets/images/plastic_bottle.png',
      correctCategory: WasteCategory.recyclable,
      funFact: 'Nhựa mất đến 450 năm để phân hủy hoàn toàn!',
    ),
    GameQuestion(
      name: 'Pin cũ',
      imagePath: 'assets/images/battery.png',
      correctCategory: WasteCategory.hazardous,
      funFact: 'Một viên pin có thể làm ô nhiễm 500 lít nước.',
    ),
    // Thêm các câu hỏi khác ở đây
  ];

  int _currentIndex = 0;

  void _checkAnswer(WasteCategory selected, GameProvider provider) {
    final isCorrect = selected == _questions[_currentIndex].correctCategory;
    
    if (isCorrect) {
      provider.addScore(10);
      _showFeedback(true, _questions[_currentIndex].funFact);
    } else {
      _showFeedback(false, "Sai rồi! Hãy thử lại nhé.");
    }
  }

  void _showFeedback(bool isCorrect, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Icon(
          isCorrect ? Icons.check_circle_outline : Icons.error_outline,
          color: isCorrect ? Colors.green : Colors.red,
          size: 60,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect ? "Chính xác! +10 điểm" : "Rất tiếc!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isCorrect) {
                setState(() {
                  _currentIndex = (_currentIndex + 1) % _questions.length;
                });
              }
            },
            child: const Text("Tiếp tục"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thử thách Phân loại'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Điểm: ${gameProvider.score}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: WasteCard(question: _questions[_currentIndex]),
          ),
          const Spacer(),
          const Text("Đây là loại rác nào?", style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildActionButtons(gameProvider),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildActionButtons(GameProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _gameButton("Tái chế", Colors.blue, () => _checkAnswer(WasteCategory.recyclable, provider))),
              const SizedBox(width: 16),
              Expanded(child: _gameButton("Hữu cơ", Colors.brown, () => _checkAnswer(WasteCategory.organic, provider))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _gameButton("Nguy hại", Colors.red, () => _checkAnswer(WasteCategory.hazardous, provider))),
              const SizedBox(width: 16),
              Expanded(child: _gameButton("Thông thường", Colors.grey, () => _checkAnswer(WasteCategory.trash, provider))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gameButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'badge_inventory_screen.dart';
import 'game_provider.dart';
import 'models/game_question.dart';
import 'widgets/waste_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Map<WasteCategory, List<String>> _itemByCategory = {
    WasteCategory.recyclable: [
      'Vỏ chai nhựa', 'Lon nhôm', 'Giấy báo cũ', 'Hộp carton', 'Chai thủy tinh',
      'Hộp sữa giấy sạch', 'Lọ nhựa dầu gội', 'Túi giấy', 'Vỏ hộp kim loại', 'Giấy văn phòng',
    ],
    WasteCategory.organic: [
      'Vỏ chuối', 'Thức ăn thừa', 'Vỏ rau củ', 'Bã cà phê', 'Vỏ trứng',
      'Lá cây khô', 'Cơm thừa', 'Vỏ trái cây', 'Rau héo', 'Bã trà',
    ],
    WasteCategory.hazardous: [
      'Pin cũ', 'Bóng đèn huỳnh quang', 'Hộp thuốc hết hạn', 'Bình xịt côn trùng',
      'Ắc quy mini', 'Sơn thừa', 'Dung dịch tẩy rửa mạnh', 'Linh kiện điện tử hỏng',
      'Nhiệt kế thủy ngân', 'Hóa chất phòng thí nghiệm',
    ],
    WasteCategory.trash: [
      'Ly giấy dính cà phê', 'Khẩu trang đã dùng', 'Tã giấy', 'Xốp bẩn',
      'Khăn giấy bẩn', 'Ống hút nhựa bẩn', 'Bao bì nhiều lớp', 'Giẻ lau dính dầu',
      'Băng keo đã dùng', 'Đồ gốm vỡ',
    ],
  };

  final Map<WasteCategory, List<String>> _factsByCategory = {
    WasteCategory.recyclable: [
      'Phân loại đúng giúp vật liệu quay lại chu trình sản xuất nhanh hơn.',
      'Rửa sạch và để khô giúp tăng khả năng tái chế.',
      'Tái chế giúp giảm tiêu thụ tài nguyên thô và năng lượng.',
    ],
    WasteCategory.organic: [
      'Rác hữu cơ có thể ủ thành compost cho cây trồng.',
      'Tách rác hữu cơ giúp giảm mùi và giảm khí phát thải bãi rác.',
      'Không trộn hữu cơ với nhựa/kim loại để tránh lẫn tạp chất.',
    ],
    WasteCategory.hazardous: [
      'Rác nguy hại cần thu gom riêng, không bỏ chung rác sinh hoạt.',
      'Pin và hóa chất có thể gây ô nhiễm đất, nước nếu xử lý sai.',
      'Nên đưa rác nguy hại đến điểm thu hồi chuyên dụng.',
    ],
    WasteCategory.trash: [
      'Rác thông thường nên buộc kín trước khi bỏ vào thùng.',
      'Giảm rác thường bằng cách thay sản phẩm dùng một lần.',
      'Không lẫn rác thường vào nhóm tái chế để tránh nhiễm bẩn.',
    ],
  };

  final Map<WasteCategory, List<String>> _imageByCategory = {
    WasteCategory.recyclable: [
      'https://images.unsplash.com/photo-1523362628745-0c100150b504?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1586953208448-b95a79798f07?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=1200&q=80',
    ],
    WasteCategory.organic: [
      'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=1200&q=80',
    ],
    WasteCategory.hazardous: [
      'https://images.unsplash.com/photo-1603539444875-76e7684265dd?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1517991104123-1d56a6e81ed9?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=80',
    ],
    WasteCategory.trash: [
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1618477462146-050d2767eac4?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1621452773781-0f992fd1f5cb?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1530587191325-3db32d826c18?auto=format&fit=crop&w=1200&q=80',
    ],
  };

  late final List<GameQuestion> _questions;
  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _streak = 0;
  int _timeLeft = 15;
  int _round = 1;
  int _roundScore = 0;
  bool _isAnswerLocked = false;
  Timer? _timer;

  static const int _questionTimeLimit = 15;
  static const int _questionsPerRound = 200;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions(_questionsPerRound);
    _startTimer();
  }

  List<GameQuestion> _generateQuestions(int count) {
    final random = Random();
    final categories = WasteCategory.values;
    final generated = <GameQuestion>[];

    for (var i = 0; i < count; i++) {
      final category = categories[random.nextInt(categories.length)];
      final names = _itemByCategory[category]!;
      final facts = _factsByCategory[category]!;
      final images = _imageByCategory[category]!;

      final name = names[random.nextInt(names.length)];
      final fact = facts[random.nextInt(facts.length)];
      final image = images[random.nextInt(images.length)];

      generated.add(
        GameQuestion(
          name: name,
          imagePath: image,
          correctCategory: category,
          funFact: fact,
        ),
      );
    }

    return generated;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = _questionTimeLimit);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isAnswerLocked) return;
      if (_timeLeft <= 1) {
        timer.cancel();
        _onTimeUp();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _onTimeUp() {
    if (_isAnswerLocked) return;
    _isAnswerLocked = true;
    _streak = 0;
    _showFeedback(
      false,
      'Hết thời gian! ${_questions[_currentIndex].name} thuộc nhóm "${_labelForCategory(_questions[_currentIndex].correctCategory)}".',
    );
  }

  String _labelForCategory(WasteCategory category) {
    switch (category) {
      case WasteCategory.recyclable:
        return 'Tái chế';
      case WasteCategory.organic:
        return 'Hữu cơ';
      case WasteCategory.hazardous:
        return 'Nguy hại';
      case WasteCategory.trash:
        return 'Thông thường';
    }
  }

  void _checkAnswer(WasteCategory selected, GameProvider provider) {
    if (_isAnswerLocked) return;
    _isAnswerLocked = true;
    _timer?.cancel();
    final isCorrect = selected == _questions[_currentIndex].correctCategory;

    if (isCorrect) {
      _correctAnswers++;
      _streak++;
      final bonus = _streak >= 3 ? 5 : 0;
      final gained = 10 + bonus;
      _roundScore += gained;
      provider.addScore(gained);
      _showFeedback(true, _questions[_currentIndex].funFact);
    } else {
      _streak = 0;
      _showFeedback(
        false,
        'Sai rồi! Đáp án đúng là "${_labelForCategory(_questions[_currentIndex].correctCategory)}".',
      );
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
              isCorrect ? "Chính xác! +${_streak >= 3 ? 15 : 10} điểm" : "Rất tiếc!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (isCorrect && _streak >= 3) ...[
              const SizedBox(height: 8),
              const Text(
                'Combo Streak! +5 điểm thưởng',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = (_currentIndex + 1) % _questions.length;
                _isAnswerLocked = false;
              });
              if (_currentIndex == 0) {
                _round++;
              }
              _startTimer();
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
    final progress = (_currentIndex + 1) / _questions.length;
    final timerRatio = _timeLeft / _questionTimeLimit;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (screenWidth * 0.045).clamp(12.0, 24.0);
    final sectionGap = (screenWidth * 0.045).clamp(12.0, 20.0);
    final titleSize = (screenWidth * 0.05).clamp(16.0, 24.0);
    final scoreSize = (screenWidth * 0.043).clamp(14.0, 18.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thử thách Phân loại Pro'),
        actions: [
          IconButton(
            tooltip: 'Kho huy hiệu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BadgeInventoryScreen()),
              );
            },
            icon: const Icon(Icons.workspace_premium_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Điểm: ${gameProvider.score}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: scoreSize),
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: sectionGap),
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 0),
            padding: EdgeInsets.all((screenWidth * 0.035).clamp(10.0, 16.0)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A7B24), Color(0xFF36A844)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular((screenWidth * 0.05).clamp(14.0, 20.0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _statChip(Icons.local_fire_department_rounded, 'Streak', 'x$_streak'),
                    const SizedBox(width: 8),
                    _statChip(Icons.verified_rounded, 'Đúng', '$_correctAnswers'),
                    const SizedBox(width: 8),
                    _statChip(Icons.flag_rounded, 'Vòng', '$_round'),
                  ],
                ),
                SizedBox(height: (screenWidth * 0.025).clamp(8.0, 12.0)),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: progress.clamp(0, 1),
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: (screenWidth * 0.03).clamp(8.0, 14.0)),
                    Text(
                      '${_currentIndex + 1}/${_questions.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: (screenWidth * 0.036).clamp(12.0, 15.0),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: (screenWidth * 0.025).clamp(8.0, 12.0)),
                Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Thời gian còn lại: ${_timeLeft}s',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: (screenWidth * 0.035).clamp(12.0, 15.0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: timerRatio.clamp(0, 1),
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: sectionGap),
          if (gameProvider.earnedBadges.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: gameProvider.earnedBadges.map((badgeName) {
                    final icon = gameProvider.badgeIcons[badgeName] ?? '🏅';
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        '$icon $badgeName',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          SizedBox(height: (sectionGap * 0.8)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: WasteCard(question: _questions[_currentIndex]),
          ),
          SizedBox(height: sectionGap),
          Text(
            "Đây là loại rác nào?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: titleSize * 0.78, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: (screenWidth * 0.015).clamp(4.0, 8.0)),
          Text(
            _questions[_currentIndex].name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: sectionGap),
          _buildActionButtons(gameProvider),
          Padding(
            padding: EdgeInsets.only(top: sectionGap),
            child: Text(
              'Điểm vòng hiện tại: $_roundScore',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: (screenWidth * 0.037).clamp(12.0, 15.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              '$label: $value',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(GameProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (screenWidth * 0.06).clamp(14.0, 30.0);
    final gap = (screenWidth * 0.04).clamp(10.0, 18.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _gameButton("Tái chế", Colors.blue, () => _checkAnswer(WasteCategory.recyclable, provider))),
              SizedBox(width: gap),
              Expanded(child: _gameButton("Hữu cơ", Colors.brown, () => _checkAnswer(WasteCategory.organic, provider))),
            ],
          ),
          SizedBox(height: gap),
          Row(
            children: [
              Expanded(child: _gameButton("Nguy hại", Colors.red, () => _checkAnswer(WasteCategory.hazardous, provider))),
              SizedBox(width: gap),
              Expanded(child: _gameButton("Thông thường", Colors.grey, () => _checkAnswer(WasteCategory.trash, provider))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gameButton(String label, Color color, VoidCallback onTap) {
    final screenWidth = MediaQuery.of(context).size.width;
    final verticalPadding = (screenWidth * 0.048).clamp(12.0, 20.0);
    final fontSize = (screenWidth * 0.043).clamp(14.0, 17.0);
    final radius = (screenWidth * 0.05).clamp(14.0, 20.0);
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      child: Text(label, style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w700)),
    );
  }
}

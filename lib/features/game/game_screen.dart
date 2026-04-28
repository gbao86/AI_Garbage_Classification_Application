import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  List<GameQuestion> _questions = [];
  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _streak = 0;
  int _timeLeft = 15;
  int _round = 1;
  int _roundScore = 0;
  bool _isAnswerLocked = false;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _timer;

  static const int _questionTimeLimit = 15;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('game_questions')
          .select('''
            waste_dictionary (
              name_vi,
              image_url,
              fun_fact,
              is_active,
              waste_groups (
                code
              )
            )
          ''')
          .eq('is_active', true);

      final List<dynamic> data = response as List<dynamic>;
      
      if (data.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Không có câu hỏi nào được tìm thấy trong hệ thống.";
        });
        return;
      }

      final fetchedQuestions = data.map((item) {
        final dict = item['waste_dictionary'] as Map<String, dynamic>;
        final group = dict['waste_groups'] as Map<String, dynamic>;
        final categoryCode = group['code'] as String;

        final category = WasteCategory.values.firstWhere(
          (e) => e.name == categoryCode,
          orElse: () => WasteCategory.trash,
        );

        return GameQuestion(
          name: dict['name_vi'] ?? '',
          imagePath: dict['image_url'] ?? '',
          correctCategory: category,
          funFact: dict['fun_fact'] ?? '',
        );
      }).where((q) {
        // Lọc bỏ các câu hỏi không hợp lệ hoặc là báo cáo lỗi chưa duyệt kỹ
        return q.name.isNotEmpty && 
               !q.name.contains('Báo cáo rác sai') &&
               q.imagePath.isNotEmpty;
      }).toList();

      if (fetchedQuestions.isEmpty) {
         setState(() {
          _isLoading = false;
          _errorMessage = "Dữ liệu câu hỏi hiện chưa sẵn sàng. Vui lòng quay lại sau.";
        });
        return;
      }

      fetchedQuestions.shuffle();

      if (mounted) {
        setState(() {
          _questions = fetchedQuestions;
          _isLoading = false;
        });
        _startTimer();
        // Đánh dấu đã chơi game
        SharedPreferences.getInstance().then((prefs) => prefs.setBool('has_played_game', true));
      }
    } catch (e) {
      debugPrint('Error loading game questions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Lỗi kết nối dữ liệu. Vui lòng thử lại sau.";
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_questions.isEmpty) return;
    
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
    if (_isAnswerLocked || _questions.isEmpty) return;
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
    if (_isAnswerLocked || _questions.isEmpty) return;
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
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.network(
                'https://lottie.host/1bc0d768-27bd-4144-957d-5ba2b0a3d84c/sN7k7FPwgG.json',
                width: 200,
                height: 200,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 60, height: 60,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Đang tải câu hỏi...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chuẩn bị thử thách cho bạn...',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.network(
                  'https://lottie.host/02e56a23-0793-4214-8847-7aecde14b950/Yf3lmrUXqk.json',
                  width: 160,
                  height: 160,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.error_outline_rounded,
                    size: 80,
                    color: Colors.red.shade300,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Không thể tải dữ liệu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _loadGameData,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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

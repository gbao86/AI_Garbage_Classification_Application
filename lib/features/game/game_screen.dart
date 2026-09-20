import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'badge_inventory_screen.dart';
import 'game_provider.dart';
import 'models/game_question.dart';
import 'widgets/round_summary_sheet.dart';
import 'widgets/waste_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  List<GameQuestion> _questions = [];
  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _timeLeft = 15;
  int _round = 1;
  int _roundScore = 0;
  bool _isAnswerLocked = false;
  bool _isLoading = true;
  bool _showHint = false;
  String? _errorMessage;
  Timer? _timer;

  // Round progression (10 questions per round)
  static const int _questionsPerRound = 10;
  static const int _questionTimeLimit = 15;
  final List<QuestionAttemptResult> _roundAttempts = [];

  // Tapped feedback state
  WasteCategory? _selectedCategory;
  bool? _isLastSelectionCorrect;

  // In-Game Non-blocking Feedback State
  String? _floatingScoreText;
  Color _floatingScoreColor = Colors.green;
  String? _bannerMessage;
  bool _isBannerError = false;
  String? _currentFunFact;

  // Animation controllers
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreFadeAnimation;
  late Animation<Offset> _scoreSlideAnimation;

  late AnimationController _cardAnimController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();

    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scoreFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _scoreAnimController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );
    _scoreSlideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.8)).animate(
      CurvedAnimation(parent: _scoreAnimController, curve: Curves.easeOutCubic),
    );

    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _cardScaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOutBack),
    );
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeIn),
    );

    _cardAnimController.forward();
    _loadGameData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scoreAnimController.dispose();
    _cardAnimController.dispose();
    super.dispose();
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
        final categoryCode = (group['code'] ?? '').toString().toLowerCase();

        final category = WasteCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == categoryCode,
          orElse: () => WasteCategory.trash,
        );

        return GameQuestion(
          name: dict['name_vi'] ?? '',
          imagePath: dict['image_url'] ?? '',
          correctCategory: category,
          funFact: dict['fun_fact'] ?? '',
        );
      }).where((q) {
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
          _roundAttempts.clear();
          _roundScore = 0;
          _correctAnswers = 0;
          _streak = 0;
          _maxStreak = 0;
          _currentIndex = 0;
        });
        _startTimer();
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
    final q = _questions[_currentIndex];

    HapticFeedback.heavyImpact();
    _streak = 0;
    _roundAttempts.add(QuestionAttemptResult(
      question: q,
      isCorrect: false,
      selectedCategory: null,
    ));

    _showFloatingNotification(
      'Hết giờ! "${q.name}" là rác ${_labelForCategory(q.correctCategory)}',
      isError: true,
    );

    _advanceToNextQuestion(isCorrect: false);
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
        return 'Rác khác';
    }
  }

  void _selectCategory(WasteCategory category, GameProvider provider) {
    if (_isAnswerLocked || _questions.isEmpty) return;
    _isAnswerLocked = true;
    _timer?.cancel();

    final currentQ = _questions[_currentIndex];
    final isCorrect = category == currentQ.correctCategory;

    setState(() {
      _selectedCategory = category;
      _isLastSelectionCorrect = isCorrect;
    });

    _roundAttempts.add(QuestionAttemptResult(
      question: currentQ,
      isCorrect: isCorrect,
      selectedCategory: category,
    ));

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      _correctAnswers++;
      _streak++;
      if (_streak > _maxStreak) _maxStreak = _streak;

      final bonus = _streak >= 3 ? 5 : 0;
      final gained = 10 + bonus;
      _roundScore += gained;
      provider.addScore(gained);

      _triggerFloatingScore(gained, _streak);

      if (currentQ.funFact.isNotEmpty) {
        setState(() {
          _currentFunFact = currentQ.funFact;
        });
      }

      _showFloatingNotification(
        _streak >= 3 ? '🔥 COMBO x$_streak! Quá chuẩn!' : 'Chính xác! +$gained XP',
        isError: false,
      );
    } else {
      HapticFeedback.heavyImpact();
      _streak = 0;
      _showFloatingNotification(
        'Chưa đúng! "${currentQ.name}" thuộc nhóm ${_labelForCategory(currentQ.correctCategory)}',
        isError: true,
      );
    }

    _advanceToNextQuestion(isCorrect: isCorrect);
  }

  void _triggerFloatingScore(int gained, int streak) {
    setState(() {
      _floatingScoreText = streak >= 3 ? '+$gained XP  🔥x$streak' : '+$gained XP';
      _floatingScoreColor = streak >= 3 ? Colors.orangeAccent : const Color(0xFF10B981);
    });
    _scoreAnimController.reset();
    _scoreAnimController.forward();
  }

  void _showFloatingNotification(String message, {required bool isError}) {
    setState(() {
      _bannerMessage = message;
      _isBannerError = isError;
    });

    Timer(const Duration(milliseconds: 2200), () {
      if (mounted && _bannerMessage == message) {
        setState(() => _bannerMessage = null);
      }
    });
  }

  void _advanceToNextQuestion({required bool isCorrect}) {
    // Shorter delay for correct answers (320ms), slightly longer for wrong answers (550ms) to see the correct group
    final delayMs = isCorrect ? 320 : 550;

    Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;

      if (_roundAttempts.length >= _questionsPerRound ||
          _currentIndex >= _questions.length - 1) {
        _showRoundSummary();
        return;
      }

      setState(() {
        _currentIndex = (_currentIndex + 1) % _questions.length;
        _isAnswerLocked = false;
        _showHint = false;
        _selectedCategory = null;
        _isLastSelectionCorrect = null;
      });

      _cardAnimController.reset();
      _cardAnimController.forward();
      _startTimer();
    });
  }

  void _showRoundSummary() {
    _timer?.cancel();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RoundSummarySheet(
        round: _round,
        roundScore: _roundScore,
        totalQuestions: _roundAttempts.length,
        correctCount: _correctAnswers,
        maxStreak: _maxStreak,
        attempts: List.from(_roundAttempts),
        onPlayAgain: () {
          Navigator.pop(ctx);
          setState(() {
            _round++;
            _roundScore = 0;
            _roundAttempts.clear();
            _streak = 0;
            _maxStreak = 0;
            _correctAnswers = 0;
            _isAnswerLocked = false;
            _showHint = false;
            _currentFunFact = null;
            _selectedCategory = null;
            _isLastSelectionCorrect = null;
            _currentIndex = (_currentIndex + 1) % _questions.length;
          });
          _cardAnimController.reset();
          _cardAnimController.forward();
          _startTimer();
        },
        onExit: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.network(
                'https://lottie.host/1bc0d768-27bd-4144-957d-5ba2b0a3d84c/sN7k7FPwgG.json',
                width: 180,
                height: 180,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Đang nạp bộ câu hỏi phân loại...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
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
                Icon(Icons.wifi_off_rounded, size: 72, color: Colors.red.shade300),
                const SizedBox(height: 18),
                Text(
                  'Không thể tải dữ liệu',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Thử lại ngay'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _loadGameData,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final gameProvider = Provider.of<GameProvider>(context);
    final roundProgress = (_roundAttempts.length + 1).clamp(1, _questionsPerRound) / _questionsPerRound;
    final timerRatio = _timeLeft / _questionTimeLimit;
    final currentQ = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Vòng $_round: Thử thách Phân loại',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Kho huy hiệu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BadgeInventoryScreen()),
              );
            },
            icon: const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${gameProvider.score}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;

            // Hero Card dimensions calibrated for full visibility
            final heroCardWidth = (availableWidth * 0.90).clamp(280.0, 440.0);
            final heroCardHeight = (availableHeight * 0.46).clamp(220.0, 310.0);

            return Column(
              children: [
                // Top Status Header (Streak, Timer, Progress)
                _buildCompactStatsHeader(
                  roundProgress: roundProgress,
                  timerRatio: timerRatio,
                  isDark: isDark,
                ),

                // In-Game Floating Feedback Banner (Non-blocking)
                _buildNotificationPill(isDark),

                // Center: Big Hero Card Area (The primary visual subject, completely unobscured)
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        ScaleTransition(
                          scale: _cardScaleAnimation,
                          child: FadeTransition(
                            opacity: _cardFadeAnimation,
                            child: SizedBox(
                              width: heroCardWidth,
                              height: heroCardHeight,
                              child: WasteCard(
                                question: currentQ,
                                showHint: _showHint,
                                onToggleHint: () {
                                  setState(() => _showHint = !_showHint);
                                },
                              ),
                            ),
                          ),
                        ),

                        // Floating XP Indicator Animation
                        if (_floatingScoreText != null)
                          Positioned(
                            top: -24,
                            child: SlideTransition(
                              position: _scoreSlideAnimation,
                              child: FadeTransition(
                                opacity: _scoreFadeAnimation,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _floatingScoreColor,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _floatingScoreColor.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    _floatingScoreText!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Micro Fun Fact Capsule (Non-blocking educational insight)
                if (_currentFunFact != null && _currentFunFact!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              _currentFunFact!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom: 2x2 Thumb-Friendly Tap-to-Choose Dock (No dragging, just tap!)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: _buildThumbFriendlyTapDock(
                    gameProvider: gameProvider,
                    isDark: isDark,
                    correctCategory: currentQ.correctCategory,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactStatsHeader({
    required double roundProgress,
    required double timerRatio,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0x08000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Streak Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _streak >= 3 ? Colors.deepOrange.shade50 : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _streak >= 3 ? Colors.deepOrange.shade300 : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _streak >= 3 ? '🔥' : '⚡',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Streak x$_streak',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _streak >= 3 ? Colors.deepOrange : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),

              // Round Progress Pill
              Text(
                'Câu ${_roundAttempts.length + 1}/$_questionsPerRound',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),

              // Timer Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _timeLeft <= 4 ? Colors.red.shade50 : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _timeLeft <= 4 ? Colors.red.shade300 : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: _timeLeft <= 4 ? Colors.red : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_timeLeft}s',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _timeLeft <= 4 ? Colors.red : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Dual Progress Bar: Round progress (Green) + Timer (Amber)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: roundProgress.clamp(0.0, 1.0),
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: timerRatio.clamp(0.0, 1.0),
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _timeLeft <= 4 ? Colors.red : Colors.amber.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPill(bool isDark) {
    if (_bannerMessage == null) return const SizedBox(height: 24);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 28,
      margin: const EdgeInsets.only(top: 2, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _isBannerError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isBannerError ? Colors.red : Colors.green).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _bannerMessage!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThumbFriendlyTapDock({
    required GameProvider gameProvider,
    required bool isDark,
    required WasteCategory correctCategory,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTapButton(
                category: WasteCategory.recyclable,
                emoji: '♻️',
                title: 'Tái chế',
                subtitle: 'Chai lọ, giấy, kim loại...',
                themeColor: const Color(0xFF0284C7),
                isDark: isDark,
                gameProvider: gameProvider,
                correctCategory: correctCategory,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTapButton(
                category: WasteCategory.organic,
                emoji: '🍃',
                title: 'Hữu cơ',
                subtitle: 'Thức ăn, vỏ rau củ quả...',
                themeColor: const Color(0xFF16A34A),
                isDark: isDark,
                gameProvider: gameProvider,
                correctCategory: correctCategory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTapButton(
                category: WasteCategory.hazardous,
                emoji: '☠️',
                title: 'Nguy hại',
                subtitle: 'Pin, bóng đèn, hóa chất...',
                themeColor: const Color(0xFFE11D48),
                isDark: isDark,
                gameProvider: gameProvider,
                correctCategory: correctCategory,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTapButton(
                category: WasteCategory.trash,
                emoji: '🗑️',
                title: 'Rác khác',
                subtitle: 'Hộp xốp, túi bẩn, tã...',
                themeColor: const Color(0xFFD97706),
                isDark: isDark,
                gameProvider: gameProvider,
                correctCategory: correctCategory,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTapButton({
    required WasteCategory category,
    required String emoji,
    required String title,
    required String subtitle,
    required Color themeColor,
    required bool isDark,
    required GameProvider gameProvider,
    required WasteCategory correctCategory,
  }) {
    // Check if this button is currently selected or being highlighted
    final isSelected = _selectedCategory == category;
    final isCorrectTarget = _selectedCategory != null && category == correctCategory;
    final isWrongSelection = isSelected && _isLastSelectionCorrect == false;

    Color buttonBg;
    Color buttonBorder;
    Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    if (isSelected && _isLastSelectionCorrect == true) {
      buttonBg = const Color(0xFF10B981).withValues(alpha: 0.25);
      buttonBorder = const Color(0xFF10B981);
      textColor = const Color(0xFF10B981);
    } else if (isWrongSelection) {
      buttonBg = const Color(0xFFEF4444).withValues(alpha: 0.25);
      buttonBorder = const Color(0xFFEF4444);
      textColor = const Color(0xFFEF4444);
    } else if (isCorrectTarget) {
      // Highlight correct button when user picked the wrong one
      buttonBg = const Color(0xFF10B981).withValues(alpha: 0.2);
      buttonBorder = const Color(0xFF10B981);
    } else {
      buttonBg = isDark ? const Color(0xFF1E293B) : Colors.white;
      buttonBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isAnswerLocked ? null : () => _selectCategory(category, gameProvider),
        borderRadius: BorderRadius.circular(18),
        splashColor: themeColor.withValues(alpha: 0.2),
        highlightColor: themeColor.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: buttonBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: buttonBorder,
              width: (isSelected || isCorrectTarget) ? 2.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected || isCorrectTarget)
                    ? buttonBorder.withValues(alpha: 0.35)
                    : (isDark ? Colors.black26 : const Color(0x06000000)),
                blurRadius: (isSelected || isCorrectTarget) ? 12 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Emoji / Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (isSelected || isCorrectTarget)
                      ? buttonBorder.withValues(alpha: 0.2)
                      : themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isWrongSelection
                        ? '❌'
                        : (isSelected || isCorrectTarget ? '✅' : emoji),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

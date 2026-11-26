import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phan_loai_rac_qua_hinh_anh/features/game/models/game_question.dart';
import 'package:phan_loai_rac_qua_hinh_anh/features/game/widgets/round_summary_sheet.dart';
import 'package:phan_loai_rac_qua_hinh_anh/screens/waste_symbols_screen.dart';
import 'package:phan_loai_rac_qua_hinh_anh/theme/app_theme.dart';

void main() {
  group('Widget UI Tests', () {
    testWidgets('WasteSymbolsScreen renders title and filter chips', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const WasteSymbolsScreen(),
        ),
      );

      expect(find.text('Ký hiệu rác thải & bao bì'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('🇻🇳 Việt Nam'), findsOneWidget);
      expect(find.text('🌍 Quốc tế'), findsOneWidget);

      await tester.tap(find.text('🇻🇳 Việt Nam'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('🌍 Quốc tế'));
      await tester.pumpAndSettle();
    });

    testWidgets('RoundSummarySheet renders round summary header and items', (WidgetTester tester) async {
      bool playAgainPressed = false;
      bool exitPressed = false;

      final sampleAttempts = [
        QuestionAttemptResult(
          question: GameQuestion(
            name: 'Chai nhựa PET',
            imagePath: '',
            correctCategory: WasteCategory.recyclable,
            funFact: 'Nhựa PET có thể tái chế thành sợi vải.',
          ),
          isCorrect: true,
          selectedCategory: WasteCategory.recyclable,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RoundSummarySheet(
              round: 1,
              roundScore: 100,
              totalQuestions: 10,
              correctCount: 9,
              maxStreak: 5,
              attempts: sampleAttempts,
              onPlayAgain: () => playAgainPressed = true,
              onExit: () => exitPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Hoàn thành Vòng 1! 🎉'), findsOneWidget);
      expect(find.text('Tổng kết kết quả & Sổ tay kiến thức xanh'), findsOneWidget);
      expect(find.text('Chai nhựa PET'), findsOneWidget);
      expect(playAgainPressed, isFalse);
      expect(exitPressed, isFalse);
    });
  });
}

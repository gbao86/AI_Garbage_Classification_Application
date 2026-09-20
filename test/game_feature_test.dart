import 'package:flutter_test/flutter_test.dart';
import 'package:phan_loai_rac_qua_hinh_anh/features/game/models/game_question.dart';
import 'package:phan_loai_rac_qua_hinh_anh/features/game/widgets/round_summary_sheet.dart';

void main() {
  group('Game Feature Logic Tests', () {
    test('GameQuestion initializes correctly', () {
      final q = GameQuestion(
        name: 'Vỏ chai nhựa PET',
        imagePath: 'https://example.com/pet.jpg',
        correctCategory: WasteCategory.recyclable,
        funFact: 'Nhựa PET có thể tái chế thành áo khoác.',
      );

      expect(q.name, 'Vỏ chai nhựa PET');
      expect(q.imagePath, 'https://example.com/pet.jpg');
      expect(q.correctCategory, WasteCategory.recyclable);
      expect(q.funFact, contains('Nhựa PET'));
    });

    test('QuestionAttemptResult tracks user results accurately', () {
      final q = GameQuestion(
        name: 'Vỏ chuối',
        imagePath: 'https://example.com/banana.jpg',
        correctCategory: WasteCategory.organic,
        funFact: 'Vỏ chuối phân hủy tạo phân bón hữu cơ giàu kali.',
      );

      final resultCorrect = QuestionAttemptResult(
        question: q,
        isCorrect: true,
        selectedCategory: WasteCategory.organic,
      );

      expect(resultCorrect.isCorrect, isTrue);
      expect(resultCorrect.selectedCategory, WasteCategory.organic);

      final resultWrong = QuestionAttemptResult(
        question: q,
        isCorrect: false,
        selectedCategory: WasteCategory.trash,
      );

      expect(resultWrong.isCorrect, isFalse);
      expect(resultWrong.selectedCategory, WasteCategory.trash);
    });

    test('WasteCategory enum contains all 4 required taxonomy groups', () {
      expect(WasteCategory.values.length, 4);
      expect(WasteCategory.values, contains(WasteCategory.recyclable));
      expect(WasteCategory.values, contains(WasteCategory.organic));
      expect(WasteCategory.values, contains(WasteCategory.hazardous));
      expect(WasteCategory.values, contains(WasteCategory.trash));
    });
  });
}

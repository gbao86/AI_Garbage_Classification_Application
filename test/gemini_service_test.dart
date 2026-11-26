import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:phan_loai_rac_qua_hinh_anh/services/gemini_service.dart';

void main() {
  group('GeminiService.sanitizeModelName', () {
    test('accepts clean valid model name', () {
      expect(
        GeminiService.sanitizeModelName('gemini-4-hydrogen'),
        'gemini-4-hydrogen',
      );
    });

    test('extracts model from Supabase JSONB Map', () {
      expect(
        GeminiService.sanitizeModelName({'model': 'gemini-4-hydrogen'}),
        'gemini-4-hydrogen',
      );
    });

    test('strips stray parentheses, braces, brackets, quotes, and spaces', () {
      expect(
        GeminiService.sanitizeModelName('  ((gemini-4-hydrogen))  '),
        'gemini-4-hydrogen',
      );
      expect(
        GeminiService.sanitizeModelName('{{ "gemini-3.8-flash" }}'),
        'gemini-3.8-flash',
      );
      expect(
        GeminiService.sanitizeModelName("['gemini-2.5-flash-lite']"),
        'gemini-2.5-flash-lite',
      );
    });

    test('extracts model from nested JSON string', () {
      expect(
        GeminiService.sanitizeModelName('{"model": "gemini-4-hydrogen"}'),
        'gemini-4-hydrogen',
      );
    });

    test('strips leading models/ prefix', () {
      expect(
        GeminiService.sanitizeModelName('models/gemini-4-hydrogen'),
        'gemini-4-hydrogen',
      );
    });

    test('returns null for null, empty, or invalid model strings', () {
      expect(GeminiService.sanitizeModelName(null), isNull);
      expect(GeminiService.sanitizeModelName(''), isNull);
      expect(GeminiService.sanitizeModelName('   (( {} ))  '), isNull);
      expect(GeminiService.sanitizeModelName('bad@model#name!'), isNull);
    });
  });

  group('GeminiService.friendlyErrorMessage', () {
    test('returns overload message for 503 UNAVAILABLE', () {
      final msg = GeminiService.friendlyErrorMessage(
        Exception('Server Error [503]: high demand UNAVAILABLE'),
      );
      expect(msg, contains('quá tải tạm thời'));
    });

    test('returns quota message for 429 RESOURCE_EXHAUSTED', () {
      final msg = GeminiService.friendlyErrorMessage(
        Exception('Lỗi API [429]: RESOURCE_EXHAUSTED'),
      );
      expect(msg, contains('hạn mức'));
    });

    test('returns timeout message for TimeoutException', () {
      final msg = GeminiService.friendlyErrorMessage(
        TimeoutException('Request timed out'),
      );
      expect(msg, contains('quá thời gian chờ'));
    });

    test('returns offline message for SocketException', () {
      final msg = GeminiService.friendlyErrorMessage(
        const SocketException('Failed host lookup'),
      );
      expect(msg, contains('Không có kết nối mạng'));
    });

    test('returns generic safe message for unknown error', () {
      final msg = GeminiService.friendlyErrorMessage(
        Exception('Unexpected internal failure'),
      );
      expect(msg, contains('Không thể kết nối Gemini AI'));
    });
  });
}

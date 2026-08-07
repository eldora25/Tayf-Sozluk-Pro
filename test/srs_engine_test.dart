import 'package:flutter_test/flutter_test.dart';
import 'package:tayf_sozluk_pro/core/srs_engine.dart'; // Kendi proje adınıza göre yolu ayarlayın

void main() {
  group('SRS Engine Offset Hesaplama Testleri', () {
    test('Seviye 1 kelime için 1 günlük milisaniye dönmeli', () {
      const int oneDay = 24 * 60 * 60 * 1000;
      expect(getNextReviewOffset(1), oneDay);
    });

    test('Seviye 3 kelime için 4 günlük milisaniye dönmeli', () {
      const int fourDays = 4 * 24 * 60 * 60 * 1000;
      expect(getNextReviewOffset(3), fourDays);
    });

    test('Seviye 5 kelime için 14 günlük milisaniye dönmeli', () {
      const int fourteenDays = 14 * 24 * 60 * 60 * 1000;
      expect(getNextReviewOffset(5), fourteenDays);
    });

    test('Bilinmeyen bir seviye için 0 dönmeli', () {
      expect(getNextReviewOffset(99), 0);
    });
  });
}

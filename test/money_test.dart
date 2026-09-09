import 'package:calc_money/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMoney', () {
    test('tam lirayı gösterir', () {
      expect(formatMoney(1250), '₺12,50');
      expect(formatMoney(0), '₺0,00');
    });

    test('binlik ayıracı kullanır', () {
      expect(formatMoney(123456), '₺1.234,56');
      expect(formatMoney(123456789), '₺1.234.567,89');
    });

    test('negatif değeri işaretler', () {
      expect(formatMoney(-123456), '-₺1.234,56');
    });
  });

  group('kurusToGirdi', () {
    test('form alanına uygun metin üretir', () {
      expect(kurusToGirdi(14999), '149,99');
      expect(kurusToGirdi(100), '1');
      expect(kurusToGirdi(12), '0,12');
    });
  });

  group('parseToKurus', () {
    test('virgüllü ondalığı çözer', () {
      expect(parseToKurus('12,5'), 1250);
      expect(parseToKurus('149,99'), 14999);
      expect(parseToKurus('1.234,56'), 123456);
    });

    test('noktalı ondalığı çözer', () {
      expect(parseToKurus('149.99'), 14999);
      expect(parseToKurus('1234.56'), 123456);
    });

    test('binlik ayracını çözer', () {
      expect(parseToKurus('1.500'), 150000);
      expect(parseToKurus('1500'), 150000);
    });

    test('geçersiz girişlerde null döner', () {
      expect(parseToKurus(''), isNull);
      expect(parseToKurus('abc'), isNull);
      expect(parseToKurus('-5'), isNull);
    });
  });
}

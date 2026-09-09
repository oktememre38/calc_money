import 'package:calc_money/utils/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monthName Türkçe ay adı döner', () {
    expect(monthName(1), 'Ocak');
    expect(monthName(9), 'Eylül');
    expect(monthName(12), 'Aralık');
  });

  test('dateKey ISO biçiminde üretir', () {
    expect(dateKey(DateTime(2026, 9, 9)), '2026-09-09');
    expect(dateKey(DateTime(2026, 1, 1)), '2026-01-01');
  });

  test('monthKey ay önekini üretir', () {
    expect(monthKey(DateTime(2026, 9, 9)), '2026-09');
  });

  test('dayLabelFromKey okunur etiket üretir', () {
    expect(dayLabelFromKey('2026-09-09'), '9 Eylül 2026');
    expect(dayLabelFromKey('2025-01-01'), '1 Ocak 2025');
  });

  test('donemEtiketi kesim kapalıyken takvim ayını verir', () {
    expect(donemEtiketi(DateTime(2026, 9, 20), 0), '2026-09');
    expect(donemEtiketi(DateTime(2026, 9, 1), 0), '2026-09');
  });

  test('donemEtiketi kesim gününden sonrasını sonraki aya yazar', () {
    // Kesim günü 10: 10'una kadar (dahil) o ay, 11'i sonrası sonraki ay.
    expect(donemEtiketi(DateTime(2026, 9, 10), 10), '2026-09');
    expect(donemEtiketi(DateTime(2026, 9, 11), 10), '2026-10');
    expect(donemEtiketi(DateTime(2026, 9, 30), 10), '2026-10');
    expect(donemEtiketi(DateTime(2026, 10, 5), 10), '2026-10');
  });

  test('donemEtiketi yıl sonunda taşmayı doğru yazar', () {
    expect(donemEtiketi(DateTime(2026, 12, 20), 10), '2027-01');
    expect(donemEtiketi(DateTime(2026, 12, 1), 10), '2026-12');
  });
}

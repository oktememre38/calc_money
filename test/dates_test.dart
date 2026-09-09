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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gameon/src/core/format/persian_datetime.dart';

void main() {
  test('converts latin digits to Persian digits', () {
    expect(PersianDateTime.digits('1405/07/13 16:32'), '۱۴۰۵/۰۷/۱۳ ۱۶:۳۲');
  });

  test('formats Jalali date with Persian month name', () {
    final value = DateTime(2026, 10, 5, 16, 32);
    final formatted = PersianDateTime.date(value);
    expect(formatted, contains('مهر'));
    expect(formatted, isNot(contains('2026')));
  });

  test('formats time using Persian digits', () {
    final value = DateTime(2026, 10, 5, 16, 32);
    expect(PersianDateTime.time(value), '۱۶:۳۲');
  });
}

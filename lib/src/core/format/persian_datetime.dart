import 'package:shamsi_date/shamsi_date.dart';

abstract final class PersianDateTime {
  static const _digits = <String>['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  static const _months = <String>[
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static String digits(Object value) {
    var text = value.toString();
    for (var i = 0; i < 10; i++) {
      text = text.replaceAll('$i', _digits[i]);
    }
    return text;
  }

  static String date(DateTime value) {
    final jalali = Jalali.fromDateTime(value.toLocal());
    return '${digits(jalali.day)} ${_months[jalali.month - 1]} ${digits(jalali.year)}';
  }

  static String time(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return digits('$hour:$minute');
  }

  static String dateTime(DateTime value) => '${date(value)}، ساعت ${time(value)}';
}

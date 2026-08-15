import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final NumberFormat _number = NumberFormat.decimalPattern('id_ID');
  static final DateFormat _date = DateFormat('d MMMM yyyy', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _dateTime = DateFormat('d MMMM yyyy, HH.mm', 'id_ID');

  static String rupiah(int value) => _rupiah.format(value);

  static String kilometer(int value) => '${_number.format(value)} km';

  static String date(DateTime value) => _date.format(value.toLocal());

  static String monthYear(DateTime value) {
    return _monthYear.format(value.toLocal());
  }

  static String dateTime(DateTime value) {
    return '${_dateTime.format(value.toLocal())} WIB';
  }
}

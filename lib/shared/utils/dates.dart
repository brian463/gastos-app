import 'package:intl/intl.dart';

class Dates {
  static final DateFormat _dayFmt = DateFormat('yyyy-MM-dd');
  static String ymd(DateTime dt) => _dayFmt.format(dt);
  static DateTime parseYmd(String s) => DateTime.parse(s);
}
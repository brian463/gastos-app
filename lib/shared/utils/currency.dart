import 'package:intl/intl.dart';

class Currency {
  static final NumberFormat _fmt = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/ ',
    decimalDigits: 2,
  );

  static String format(num value) => _fmt.format(value);
}
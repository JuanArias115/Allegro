import 'package:intl/intl.dart';

/// Formato de moneda (COP) y fechas, consistente en toda la app.
class Formatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
  );

  static final DateFormat _date = DateFormat('d MMM yyyy', 'es');
  static final DateFormat _dateShort = DateFormat('d MMM', 'es');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, h:mm a', 'es');
  static final DateFormat _weekday = DateFormat("EEEE, d 'de' MMMM", 'es');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy', 'es');

  static String money(num value) => _currency.format(value);

  static String date(DateTime d) => _date.format(d);

  /// "viernes, 19 de junio" con la primera letra en mayúscula.
  static String weekdayDate(DateTime d) {
    final s = _weekday.format(d);
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }

  /// "Junio 2026" para encabezados de calendario.
  static String monthYear(DateTime d) {
    final s = _monthYear.format(d);
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }

  static String dateShort(DateTime d) => _dateShort.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d.toLocal());

  /// Rango "12 jul – 15 jul" para mostrar estadías.
  static String dateRange(DateTime checkIn, DateTime checkOut) =>
      '${_dateShort.format(checkIn)} – ${_dateShort.format(checkOut)}';

  /// Cantidad de noches entre dos fechas.
  static int nights(DateTime checkIn, DateTime checkOut) =>
      checkOut.difference(checkIn).inDays;
}

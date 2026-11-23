/// Pure Dart helpers for local calendar dates (`YYYY-MM-DD`) and weekday masks.
final class LocalDateUtils {
  LocalDateUtils._();

  /// 7-bit mask where Monday = 1 (bit 0) and Sunday = 64 (bit 6).
  static const int allWeekdaysMask = 127;

  static String today([DateTime? now]) => format(now ?? DateTime.now());

  static String format(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime parse(String localDate) {
    final parts = localDate.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid local date format: $localDate');
    }
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static DateTime stripTime(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Evaluates whether [date] is enabled in [weekdaysMask] (Mon=1 .. Sun=64).
  static bool isScheduledOnDate(DateTime date, int weekdaysMask) {
    final bitIndex = date.weekday - 1; // DateTime.monday == 1
    return (weekdaysMask & (1 << bitIndex)) != 0;
  }

  static ({String start, String end, int daysInMonth}) monthBounds(
    int year,
    int month,
  ) {
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    return (start: format(first), end: format(last), daysInMonth: last.day);
  }

  static List<String> daysInMonthList(int year, int month) {
    final bounds = monthBounds(year, month);
    return List.generate(
      bounds.daysInMonth,
      (index) => format(DateTime(year, month, index + 1)),
    );
  }
}

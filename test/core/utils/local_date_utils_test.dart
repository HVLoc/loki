import 'package:flutter_test/flutter_test.dart';
import 'package:loki/core/error/failures.dart';
import 'package:loki/core/error/result.dart';
import 'package:loki/core/utils/local_date_utils.dart';

void main() {
  group('LocalDateUtils', () {
    test('formats and parses YYYY-MM-DD consistently', () {
      final date = DateTime(2026, 11, 5, 14, 30);
      final formatted = LocalDateUtils.format(date);
      expect(formatted, '2026-11-05');

      final parsed = LocalDateUtils.parse(formatted);
      expect(parsed, DateTime(2026, 11, 5));
    });

    test('evaluates weekday bitmask correctly (Mon=1 .. Sun=64)', () {
      const monWedFri = (1 << 0) | (1 << 2) | (1 << 4);
      expect(
        LocalDateUtils.isScheduledOnDate(
          DateTime(2026, 11, 23),
          monWedFri,
        ), // Mon
        isTrue,
      );
      expect(
        LocalDateUtils.isScheduledOnDate(
          DateTime(2026, 11, 24),
          monWedFri,
        ), // Tue
        isFalse,
      );
      expect(
        LocalDateUtils.isScheduledOnDate(
          DateTime(2026, 11, 25),
          monWedFri,
        ), // Wed
        isTrue,
      );
      expect(
        LocalDateUtils.isScheduledOnDate(
          DateTime(2026, 11, 29),
          LocalDateUtils.allWeekdaysMask,
        ),
        isTrue,
      );
    });

    test('computes month bounds accurately including leap years', () {
      final bounds = LocalDateUtils.monthBounds(2024, 2);
      expect(bounds.start, '2024-02-01');
      expect(bounds.end, '2024-02-29');
      expect(bounds.daysInMonth, 29);
    });
  });

  group('Result', () {
    test('fold dispatches success and failure branches', () {
      const Result<int, Failure> ok = Success(42);
      const Result<int, Failure> err = FailureResult(
        StorageFailure('firestore offline error'),
      );

      expect(ok.fold((v) => v * 2, (_) => -1), 84);
      expect(err.fold((v) => v, (f) => f.message.length), greaterThan(0));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/domain/usecase/compute_next_occurrence.dart';
import 'package:oikerjain/model/repeat_rule.dart';

void main() {
  group('ComputeNextOccurrenceUseCase', () {
    const useCase = ComputeNextOccurrenceUseCase();

    test('returns null for repeat none', () {
      final base = DateTime.utc(2026, 2, 15, 10).millisecondsSinceEpoch;
      final result = useCase(
        fromEpochMillis: base,
        repeatRule: RepeatRule.none,
      );

      expect(result, isNull);
    });

    test('returns +1 day for daily', () {
      final base = DateTime.utc(2026, 2, 15, 10).millisecondsSinceEpoch;
      final result = useCase(
        fromEpochMillis: base,
        repeatRule: RepeatRule.daily,
      );

      expect(
        result,
        DateTime.utc(2026, 2, 16, 10).millisecondsSinceEpoch,
      );
    });

    test('returns +7 days for weekly', () {
      final base = DateTime.utc(2026, 2, 15, 10).millisecondsSinceEpoch;
      final result = useCase(
        fromEpochMillis: base,
        repeatRule: RepeatRule.weekly,
      );

      expect(
        result,
        DateTime.utc(2026, 2, 22, 10).millisecondsSinceEpoch,
      );
    });
  });
}

import '../../model/repeat_rule.dart';

class ComputeNextOccurrenceUseCase {
  const ComputeNextOccurrenceUseCase();

  int? call({required int fromEpochMillis, required RepeatRule repeatRule}) {
    final source = DateTime.fromMillisecondsSinceEpoch(fromEpochMillis);
    switch (repeatRule) {
      case RepeatRule.none:
        return null;
      case RepeatRule.daily:
        return source.add(const Duration(days: 1)).millisecondsSinceEpoch;
      case RepeatRule.weekly:
        return source.add(const Duration(days: 7)).millisecondsSinceEpoch;
    }
  }
}

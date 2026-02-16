enum RepeatRule { none, daily, weekly }

extension RepeatRuleX on RepeatRule {
  static RepeatRule fromName(String raw) {
    switch (raw) {
      case 'none':
      case 'tidak':
        return RepeatRule.none;
      case 'daily':
      case 'harian':
        return RepeatRule.daily;
      case 'weekly':
      case 'mingguan':
        return RepeatRule.weekly;
      default:
        return RepeatRule.none;
    }
  }

  String get label {
    switch (this) {
      case RepeatRule.none:
        return 'Tidak berulang';
      case RepeatRule.daily:
        return 'Harian';
      case RepeatRule.weekly:
        return 'Mingguan';
    }
  }
}

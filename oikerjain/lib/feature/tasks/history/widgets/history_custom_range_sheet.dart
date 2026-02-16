import 'package:flutter/material.dart';

import '../../../../core/constants/ui_palette.dart';
import '../../../../core/constants/ui_typography.dart';
import '../../../../core/utils/indonesian_date_formatter.dart';
import '../../components/neu_button.dart';
import '../../components/neu_surface.dart';

enum HistoryRangeSheetAction { apply, reset }

class HistoryRangeSheetResult {
  const HistoryRangeSheetResult._({
    required this.action,
    this.startDate,
    this.endDate,
  });

  const HistoryRangeSheetResult.apply({
    required DateTime startDate,
    required DateTime endDate,
  }) : this._(
         action: HistoryRangeSheetAction.apply,
         startDate: startDate,
         endDate: endDate,
       );

  const HistoryRangeSheetResult.reset()
    : this._(action: HistoryRangeSheetAction.reset);

  final HistoryRangeSheetAction action;
  final DateTime? startDate;
  final DateTime? endDate;
}

class HistoryCustomRangeSheet extends StatefulWidget {
  const HistoryCustomRangeSheet({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<HistoryCustomRangeSheet> createState() => _HistoryCustomRangeSheetState();
}

enum _ActiveField { start, end }

class _HistoryCustomRangeSheetState extends State<HistoryCustomRangeSheet> {
  late DateTime _startDate;
  late DateTime _endDate;
  _ActiveField _activeField = _ActiveField.start;

  @override
  void initState() {
    super.initState();
    final initialStart = _dateOnly(widget.initialStartDate);
    final initialEnd = _dateOnly(widget.initialEndDate);
    if (initialStart.isAfter(initialEnd)) {
      _startDate = initialEnd;
      _endDate = initialStart;
      return;
    }
    _startDate = initialStart;
    _endDate = initialEnd;
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 18 + viewPadding),
        child: NeuSurface(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Rentang tanggal custom', style: UITypography.sectionLabel),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _RangeFieldButton(
                      key: const Key('history-range-start-field'),
                      label: 'Start',
                      value: IndonesianDateFormatter.fullDate(_startDate),
                      active: _activeField == _ActiveField.start,
                      onTap: () {
                        setState(() {
                          _activeField = _ActiveField.start;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RangeFieldButton(
                      key: const Key('history-range-end-field'),
                      label: 'End',
                      value: IndonesianDateFormatter.fullDate(_endDate),
                      active: _activeField == _ActiveField.end,
                      onTap: () {
                        setState(() {
                          _activeField = _ActiveField.end;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              NeuSurface(
                radius: 18,
                pressed: true,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      primary: UIPalette.accent,
                      onPrimary: Colors.white,
                      surface: UIPalette.base,
                      onSurface: UIPalette.textSecondary,
                    ),
                  ),
                  child: CalendarDatePicker(
                    key: const Key('history-range-calendar'),
                    initialDate: _activeField == _ActiveField.start
                        ? _startDate
                        : _endDate,
                    firstDate: _dateOnly(widget.firstDate),
                    lastDate: _dateOnly(widget.lastDate),
                    currentDate: _dateOnly(DateTime.now()),
                    onDateChanged: (value) {
                      final selected = _dateOnly(value);
                      setState(() {
                        if (_activeField == _ActiveField.start) {
                          _startDate = selected;
                          if (_startDate.isAfter(_endDate)) {
                            _endDate = _startDate;
                          }
                        } else {
                          _endDate = selected;
                          if (_endDate.isBefore(_startDate)) {
                            _startDate = _endDate;
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: NeuButton(
                      key: const Key('history-range-reset-button'),
                      radius: 12,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pop(const HistoryRangeSheetResult.reset());
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NeuButton(
                      key: const Key('history-range-cancel-button'),
                      radius: 12,
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NeuButton(
                      key: const Key('history-range-apply-button'),
                      radius: 12,
                      active: true,
                      onTap: () {
                        Navigator.of(context).pop(
                          HistoryRangeSheetResult.apply(
                            startDate: _startDate,
                            endDate: _endDate,
                          ),
                        );
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _RangeFieldButton extends StatelessWidget {
  const _RangeFieldButton({
    super.key,
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      pressed: active,
      radius: 12,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: UITypography.micro),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UITypography.captionStrong.copyWith(
              color: active ? UIPalette.accent : UIPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

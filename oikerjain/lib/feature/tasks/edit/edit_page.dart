import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/constants/ui_palette.dart';
import '../../../core/constants/ui_typography.dart';
import '../../../model/repeat_rule.dart';
import '../../../model/task.dart';
import '../../../model/task_category.dart';
import '../../../model/task_priority.dart';
import '../components/neu_button.dart';
import '../components/neu_surface.dart';
import 'edit_controller.dart';

class EditPage extends ConsumerStatefulWidget {
  const EditPage({super.key, this.task});

  final Task? task;

  @override
  ConsumerState<EditPage> createState() => _EditPageState();
}

class _EditPageState extends ConsumerState<EditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _timeController;
  late final TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    final dueAt = task?.dueAt;

    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _timeController = TextEditingController(
      text: dueAt == null ? '' : _formatTime(dueAt.hour, dueAt.minute),
    );
    _dateController = TextEditingController(
      text: dueAt == null ? '' : _formatDate(dueAt),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year.toString().padLeft(4, '0')}';
  }

  ({int hour, int minute})? _parseTime(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      return null;
    }

    final match = RegExp(r'^(\d{1,2})(?::(\d{2}))?$').firstMatch(clean);
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '0');
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return (hour: hour, minute: minute);
  }

  DateTime? _parseDate(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      return null;
    }

    final dmyMatch = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(clean);
    final ymdMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(clean);
    if (dmyMatch == null && ymdMatch == null) {
      return null;
    }

    final year = int.tryParse((dmyMatch?.group(3) ?? ymdMatch?.group(1)) ?? '');
    final month = int.tryParse(
      (dmyMatch?.group(2) ?? ymdMatch?.group(2)) ?? '',
    );
    final day = int.tryParse((dmyMatch?.group(1) ?? ymdMatch?.group(3)) ?? '');
    if (year == null || month == null || day == null) {
      return null;
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  Future<void> _pickDeadlineTime({
    required BuildContext context,
    required EditController controller,
    required String currentValue,
  }) async {
    final now = DateTime.now();
    final taskDueAt = widget.task?.dueAt;
    final currentTime =
        _parseTime(currentValue) ??
        (
          hour: taskDueAt?.hour ?? now.hour,
          minute: taskDueAt?.minute ?? now.minute,
        );

    final pickedTime = await showModalBottomSheet<({int hour, int minute})>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NeuTimePickerSheet(
        initialHour: currentTime.hour,
        initialMinute: currentTime.minute,
      ),
    );
    if (pickedTime == null) {
      return;
    }

    final formatted = _formatTime(pickedTime.hour, pickedTime.minute);
    _timeController.text = formatted;
    controller.setDueTimeText(formatted);
  }

  Future<void> _pickDeadline({
    required BuildContext context,
    required EditController controller,
    required String currentValue,
  }) async {
    final now = DateTime.now();
    final currentDate =
        _parseDate(currentValue) ??
        widget.task?.dueAt ??
        DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(now.year - 10, 1, 1);
    final lastDate = DateTime(now.year + 10, 12, 31);
    var initialDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NeuDatePickerSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
    if (pickedDate == null) {
      return;
    }

    final formatted = _formatDate(pickedDate);
    _dateController.text = formatted;
    controller.setDueDateText(formatted);
  }

  Future<void> _pickRepeatRule({
    required BuildContext context,
    required EditController controller,
    required RepeatRule currentRule,
  }) async {
    final pickedRule = await showModalBottomSheet<RepeatRule>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NeuRepeatRuleSheet(initialRule: currentRule),
    );
    if (pickedRule == null) {
      return;
    }

    controller.setRepeatRule(pickedRule);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editControllerProvider(widget.task));
    final controller = ref.read(editControllerProvider(widget.task).notifier);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: UIPalette.base,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              10,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: NeuSurface(
                      pressed: true,
                      radius: 999,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 3,
                      ),
                      child: const SizedBox(width: 26, height: 2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    state.isEditMode ? 'Edit tugas' : 'Tugas baru',
                    style: UITypography.pageTitle,
                  ),
                  const SizedBox(height: 18),
                  _FieldLabel('Judul Tugas'),
                  const SizedBox(height: 6),
                  NeuSurface(
                    pressed: true,
                    radius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      key: const Key('task-title-input'),
                      controller: _titleController,
                      onChanged: controller.setTitle,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Contoh: Review proposal klien',
                        hintStyle: UITypography.inputHint,
                      ),
                      style: UITypography.input,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('Detail Tugas'),
                  const SizedBox(height: 6),
                  NeuSurface(
                    pressed: true,
                    radius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      key: const Key('task-description-input'),
                      controller: _descriptionController,
                      onChanged: controller.setDescription,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Tambahkan detail agar lebih jelas',
                        hintStyle: UITypography.inputHint,
                      ),
                      style: UITypography.body,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _InputModule(
                          label: 'Waktu tenggat',
                          child: TextField(
                            key: const Key('task-time-input'),
                            controller: _timeController,
                            readOnly: true,
                            enableInteractiveSelection: false,
                            onTap: () => _pickDeadlineTime(
                              context: context,
                              controller: controller,
                              currentValue: _timeController.text,
                            ),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Pilih waktu',
                              hintStyle: UITypography.inputHint,
                              suffixIcon: Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: UIPalette.textMuted,
                              ),
                              suffixIconConstraints: BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                            style: UITypography.input,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InputModule(
                          label: 'Tanggal tenggat',
                          child: TextField(
                            key: const Key('task-date-input'),
                            controller: _dateController,
                            readOnly: true,
                            enableInteractiveSelection: false,
                            onTap: () => _pickDeadline(
                              context: context,
                              controller: controller,
                              currentValue: _dateController.text,
                            ),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'DD-MM-YYYY',
                              hintStyle: UITypography.inputHint,
                              suffixIcon: Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                                color: UIPalette.textMuted,
                              ),
                              suffixIconConstraints: BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                            style: UITypography.input,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Prioritas'),
                  const SizedBox(height: 8),
                  Row(
                    children: TaskPriority.values.map((priority) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: priority == TaskPriority.high ? 0 : 8,
                          ),
                          child: NeuButton(
                            active: state.priority == priority,
                            radius: 12,
                            height: 42,
                            onTap: () => controller.setPriority(priority),
                            child: Text(priority.label),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Kategori'),
                  const SizedBox(height: 8),
                  Row(
                    children: TaskCategory.values.map((category) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: category == TaskCategory.personal ? 0 : 8,
                          ),
                          child: NeuButton(
                            active: state.category == category,
                            radius: 12,
                            height: 42,
                            onTap: () => controller.setCategory(category),
                            child: Text(category.label),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Pengulangan'),
                  const SizedBox(height: 8),
                  NeuSurface(
                    key: const Key('repeat-dropdown'),
                    radius: 14,
                    onTap: () => _pickRepeatRule(
                      context: context,
                      controller: controller,
                      currentRule: state.repeatRule,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _repeatRuleIcon(state.repeatRule),
                            size: 16,
                            color: UIPalette.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.repeatRule.label,
                              style: UITypography.input,
                            ),
                          ),
                          const Icon(
                            Icons.expand_more_rounded,
                            size: 18,
                            color: UIPalette.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(state.errorMessage!, style: UITypography.error),
                  ],
                  const SizedBox(height: 18),
                  NeuButton(
                    key: const Key('save-task-button'),
                    onTap: state.isSubmitting
                        ? null
                        : () async {
                            final success = await controller.submit();
                            if (success && context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                    active: true,
                    radius: 16,
                    height: 54,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            state.isEditMode
                                ? 'Perbarui tugas'
                                : 'Simpan tugas',
                            style: UITypography.bodyStrong,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeuTimePickerSheet extends StatefulWidget {
  const _NeuTimePickerSheet({
    required this.initialHour,
    required this.initialMinute,
  });

  final int initialHour;
  final int initialMinute;

  @override
  State<_NeuTimePickerSheet> createState() => _NeuTimePickerSheetState();
}

class _NeuTimePickerSheetState extends State<_NeuTimePickerSheet> {
  late int _selectedHour;
  late int _selectedMinute;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour.clamp(0, 23).toInt();
    _selectedMinute = widget.initialMinute.clamp(0, 59).toInt();
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 20 + viewPadding),
        child: NeuSurface(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _FieldLabel('Waktu tenggat'),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text('Jam', style: UITypography.caption),
                          const SizedBox(height: 8),
                          Expanded(
                            child: NeuSurface(
                              pressed: true,
                              radius: 18,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              child: ListWheelScrollView.useDelegate(
                                key: const Key('deadline-hour-wheel'),
                                controller: _hourController,
                                itemExtent: 36,
                                diameterRatio: 1.8,
                                squeeze: 1.12,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (hour) {
                                  setState(() {
                                    _selectedHour = hour;
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 24,
                                  builder: (_, index) {
                                    final value =
                                        index.toString().padLeft(2, '0');
                                    return Center(
                                      child: Text(
                                        value,
                                        style: index == _selectedHour
                                            ? UITypography.input
                                            : textTheme.bodyMedium?.copyWith(
                                                color: UIPalette.textMuted,
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text('Menit', style: UITypography.caption),
                          const SizedBox(height: 8),
                          Expanded(
                            child: NeuSurface(
                              pressed: true,
                              radius: 18,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              child: ListWheelScrollView.useDelegate(
                                key: const Key('deadline-minute-wheel'),
                                controller: _minuteController,
                                itemExtent: 36,
                                diameterRatio: 1.8,
                                squeeze: 1.12,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (minute) {
                                  setState(() {
                                    _selectedMinute = minute;
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 60,
                                  builder: (_, index) {
                                    final value =
                                        index.toString().padLeft(2, '0');
                                    return Center(
                                      child: Text(
                                        value,
                                        style: index == _selectedMinute
                                            ? UITypography.input
                                            : textTheme.bodyMedium?.copyWith(
                                                color: UIPalette.textMuted,
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: NeuButton(
                      key: const Key('time-picker-cancel-button'),
                      radius: 12,
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeuButton(
                      key: const Key('time-picker-confirm-button'),
                      radius: 12,
                      active: true,
                      onTap: () => Navigator.of(context).pop(
                        (hour: _selectedHour, minute: _selectedMinute),
                      ),
                      child: const Text('Pilih'),
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
}

class _NeuDatePickerSheet extends StatefulWidget {
  const _NeuDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_NeuDatePickerSheet> createState() => _NeuDatePickerSheetState();
}

class _NeuDatePickerSheetState extends State<_NeuDatePickerSheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 20 + viewPadding),
        child: NeuSurface(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _FieldLabel('Tanggal tenggat'),
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
                    key: const Key('deadline-calendar'),
                    initialDate: _selectedDate,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    onDateChanged: (value) {
                      setState(() {
                        _selectedDate = DateTime(
                          value.year,
                          value.month,
                          value.day,
                        );
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
                      key: const Key('date-picker-cancel-button'),
                      radius: 12,
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeuButton(
                      key: const Key('date-picker-confirm-button'),
                      radius: 12,
                      active: true,
                      onTap: () => Navigator.of(context).pop(_selectedDate),
                      child: const Text('Pilih'),
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
}

class _NeuRepeatRuleSheet extends StatefulWidget {
  const _NeuRepeatRuleSheet({required this.initialRule});

  final RepeatRule initialRule;

  @override
  State<_NeuRepeatRuleSheet> createState() => _NeuRepeatRuleSheetState();
}

class _NeuRepeatRuleSheetState extends State<_NeuRepeatRuleSheet> {
  late RepeatRule _selectedRule;

  @override
  void initState() {
    super.initState();
    _selectedRule = widget.initialRule;
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 20 + viewPadding),
        child: NeuSurface(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _FieldLabel('Pengulangan tugas'),
              const SizedBox(height: 10),
              ...RepeatRule.values.map((rule) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: rule == RepeatRule.weekly ? 0 : 8,
                  ),
                  child: NeuButton(
                    key: Key('repeat-option-${rule.name}'),
                    active: _selectedRule == rule,
                    radius: 12,
                    height: 42,
                    onTap: () {
                      setState(() {
                        _selectedRule = rule;
                      });
                    },
                    child: Row(
                      children: <Widget>[
                        Icon(_repeatRuleIcon(rule), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rule.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: NeuButton(
                      key: const Key('repeat-picker-cancel-button'),
                      radius: 12,
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeuButton(
                      key: const Key('repeat-picker-confirm-button'),
                      radius: 12,
                      active: true,
                      onTap: () => Navigator.of(context).pop(_selectedRule),
                      child: const Text('Pilih'),
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
}

IconData _repeatRuleIcon(RepeatRule rule) {
  switch (rule) {
    case RepeatRule.none:
      return Icons.block_rounded;
    case RepeatRule.daily:
      return Icons.today_rounded;
    case RepeatRule.weekly:
      return Icons.view_week_rounded;
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(text, style: UITypography.sectionLabel),
    );
  }
}

class _InputModule extends StatelessWidget {
  const _InputModule({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FieldLabel(label),
        const SizedBox(height: 6),
        NeuSurface(
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(height: 44, child: child),
        ),
      ],
    );
  }
}

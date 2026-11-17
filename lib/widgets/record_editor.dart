import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/app_record.dart';
import '../providers/app_controller.dart';
import '../utils/date_helpers.dart';
import '../utils/app_strings.dart';

Future<void> showRecordEditor(
  BuildContext context,
  AppController controller, {
  required String type,
  AppRecord? record,
  DateTime? initialDate,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardTheme.color,
    builder: (context) => RecordEditorSheet(
      controller: controller,
      type: type,
      record: record,
      initialDate: initialDate,
    ),
  );
}

class RecordEditorSheet extends StatefulWidget {
  const RecordEditorSheet({
    super.key,
    required this.controller,
    required this.type,
    this.record,
    this.initialDate,
  });
  final AppController controller;
  final String type;
  final AppRecord? record;
  final DateTime? initialDate;

  @override
  State<RecordEditorSheet> createState() => _RecordEditorSheetState();
}

class _RecordEditorSheetState extends State<RecordEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late DateTime _date;
  DateTime? _startAt;
  DateTime? _endAt;
  DateTime? _reminderAt;
  bool _reminderEnabled = false;
  String _priority = 'Medium';
  String _frequency = 'Daily';
  String _recurrence = 'none';
  String _category = 'Personal';
  String _mood = 'Good';
  int _ml = 250;
  int _targetMl = AppConstants.defaultWaterTargetMl;
  int _minutes = 30;
  int _habitTarget = 7;
  String _habitIcon = 'fire';
  int _habitColor = 0xFFF2C45E;
  final Set<int> _weekdays = {1, 2, 3, 4, 5, 6, 7};
  bool _saving = false;

  bool get _isEditing => widget.record != null;
  String _tr(String value) => AppStrings.translate(value, widget.controller.language);
  String get _type => widget.type;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _title = TextEditingController(text: record?.title ?? _tr(_defaultTitle(_type)));
    _body = TextEditingController(text: record?.body ?? '');
    _date = record?.date ?? dateOnly(widget.initialDate ?? DateTime.now());
    _startAt = record?.startAt;
    _endAt = record?.endAt;
    final meta = record?.meta ?? const <String, dynamic>{};
    _priority = meta['priority'] as String? ?? 'Medium';
    _frequency = meta['frequency'] as String? ?? 'Daily';
    _recurrence = meta['recurrence'] as String? ?? 'none';
    _category = meta['category'] as String? ?? 'Personal';
    _mood = meta['mood'] as String? ?? 'Good';
    _ml = meta['ml'] as int? ?? 250;
    _targetMl = meta['targetMl'] as int? ?? AppConstants.defaultWaterTargetMl;
    _minutes = meta['minutes'] as int? ?? 30;
    _habitTarget = meta['target'] as int? ?? 7;
    _habitIcon = meta['icon'] as String? ?? 'fire';
    _habitColor = meta['color'] as int? ?? 0xFFF2C45E;
    final days = meta['weekdays'];
    if (days is List) {
      _weekdays
        ..clear()
        ..addAll(days.whereType<num>().map((e) => e.toInt()));
    }
    final reminder = meta['reminderAt'];
    if (reminder is String) {
      _reminderAt = DateTime.tryParse(reminder);
      _reminderEnabled = _reminderAt != null;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = '${_tr(_isEditing ? 'Edit' : 'New')} ${_tr(_label(_type))}';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 18, 14),
                child: Row(children: [
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ]),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    children: [
                      if (_type != RecordType.water && _type != RecordType.sleep && _type != RecordType.mood)
                        TextFormField(
                          controller: _title,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(labelText: _tr(_type == RecordType.habit ? 'Habit name' : 'Title'), hintText: _tr('Give it a clear name')),
                          validator: (value) => value == null || value.trim().isEmpty ? _tr('Please enter a title') : null,
                        ),
                      if (_type != RecordType.water && _type != RecordType.mood) const SizedBox(height: 14),
                      if (_type == RecordType.mood) ...[
                        Text(_tr('How are you feeling today?'), style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final mood in ['Amazing', 'Good', 'Okay', 'Low', 'Stressed'])
                            ChoiceChip(label: Text(_moodLabel(mood)), selected: _mood == mood,
                              onSelected: (_) => setState(() { _mood = mood; _title.text = mood; })),
                        ]),
                        const SizedBox(height: 14),
                      ],
                      if (_type == RecordType.water) ...[
                        Text('Water intake', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _numberStepper('Amount (ml)', _ml, 50, 1500, (v) => setState(() => _ml = v)),
                        const SizedBox(height: 12),
                        _numberStepper('Daily target (ml)', _targetMl, 250, 6000, (v) => setState(() => _targetMl = v)),
                      ],
                      if (_type == RecordType.exercise)
                        _numberStepper('Duration (minutes)', _minutes, 5, 600, (v) => setState(() => _minutes = v)),
                      if (_type == RecordType.task) ...[
                        DropdownButtonFormField<String>(
                          value: _priority,
                          decoration: const InputDecoration(labelText: 'Priority'),
                          items: ['High', 'Medium', 'Low'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          onChanged: (v) => setState(() => _priority = v ?? 'Medium'),
                        ),
                        const SizedBox(height: 14),
                        _dateRow('Scheduled date', _date, () => _pickDate()),
                        _timeRow('Scheduled time', _startAt, () => _pickTime(start: true)),
                      ],
                      if (_type == RecordType.habit) ...[
                        DropdownButtonFormField<String>(
                          value: _frequency,
                          decoration: const InputDecoration(labelText: 'Frequency'),
                          items: ['Daily', 'Weekly', 'Custom'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          onChanged: (v) => setState(() {
                            _frequency = v ?? 'Daily';
                            if (_frequency == 'Weekly' && _weekdays.length == 7) {
                              _weekdays..clear()..add(DateTime.now().weekday);
                            }
                            if (_frequency == 'Daily') {
                              _weekdays..clear()..addAll([1, 2, 3, 4, 5, 6, 7]);
                            }
                          }),
                        ),
                        DropdownButtonFormField<String>(
                          value: _habitIcon,
                          decoration: const InputDecoration(labelText: 'Habit icon'),
                          items: const [
                            DropdownMenuItem(value: 'fire', child: Text('🔥 Focus / routine')),
                            DropdownMenuItem(value: 'water', child: Text('💧 Water')),
                            DropdownMenuItem(value: 'run', child: Text('🏃 Exercise')),
                            DropdownMenuItem(value: 'book', child: Text('📖 Reading')),
                            DropdownMenuItem(value: 'meditate', child: Text('🧘 Mindfulness')),
                          ],
                          onChanged: (value) => setState(() => _habitIcon = value ?? 'fire'),
                        ),
                        const SizedBox(height: 12),
                        Text(_tr('Habit colour'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 12, children: [
                          for (final value in [0xFFF2C45E, 0xFF5968F2, 0xFFE85E7A, 0xFF37B99A, 0xFF9B8AE8, 0xFFEF9561])
                            InkWell(
                              onTap: () => setState(() => _habitColor = value),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Color(value),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _habitColor == value ? AppColors.ink : Colors.transparent, width: 2),
                                ),
                                child: _habitColor == value ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
                              ),
                            ),
                        ]),
                        if (_frequency != 'Daily') ...[
                          const SizedBox(height: 12),
                          Text(_tr('Active days'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, children: List.generate(7, (index) {
                            final day = index + 1;
                            final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            return FilterChip(
                              label: Text(labels[index]),
                              selected: _weekdays.contains(day),
                              onSelected: (selected) => setState(() {
                                if (selected) { _weekdays.add(day); } else { _weekdays.remove(day); }
                              }),
                            );
                          })),
                        ],
                        const SizedBox(height: 12),
                        _numberStepper('Weekly goal (days)', _habitTarget, 1, 7, (v) => setState(() => _habitTarget = v)),
                        const SizedBox(height: 14),
                        _timeRow('Habit reminder time', _startAt, () => _pickTime(start: true)),
                      ],
                      if (_type == RecordType.event) ...[
                        DropdownButtonFormField<String>(
                          value: _category,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: ['Personal', 'Work', 'Health', 'Family', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          onChanged: (v) => setState(() => _category = v ?? 'Personal'),
                        ),
                        const SizedBox(height: 14),
                        _dateRow('Event date', _date, () => _pickDate()),
                        _timeRow('Starts', _startAt, () => _pickTime(start: true)),
                        _timeRow('Ends', _endAt, () => _pickTime(start: false)),
                        DropdownButtonFormField<String>(
                          value: _recurrence,
                          decoration: const InputDecoration(labelText: 'Repeat'),
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
                            DropdownMenuItem(value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          ],
                          onChanged: (v) => setState(() => _recurrence = v ?? 'none'),
                        ),
                      ],
                      if (_type == RecordType.sleep) ...[
                        _dateRow('Bedtime date', _date, () => _pickDate()),
                        _timeRow('Bedtime', _startAt, () => _pickTime(start: true)),
                        _timeRow('Wake-up time', _endAt, () => _pickTime(start: false)),
                      ],
                      if (_type == RecordType.journal || _type == RecordType.note || _type == RecordType.dateNote || _type == RecordType.exercise || _type == RecordType.mood) ...[
                        if (_type == RecordType.note || _type == RecordType.dateNote || _type == RecordType.journal)
                          _dateRow('Date', _date, () => _pickDate()),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _body,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 4,
                          maxLines: 8,
                          decoration: InputDecoration(labelText: _tr(_type == RecordType.journal ? 'Journal entry' : 'Description / notes'), alignLabelWithHint: true),
                        ),
                      ],
                      if (_type == RecordType.task || _type == RecordType.habit || _type == RecordType.event) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _body,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Description (optional)', alignLabelWithHint: true),
                        ),
                      ],
                      if (_type == RecordType.exercise) ...[
                        const SizedBox(height: 12),
                        _dateRow('Activity date', _date, () => _pickDate()),
                      ],
                      if (_type != RecordType.note && _type != RecordType.dateNote && _type != RecordType.journal && _type != RecordType.mood && _type != RecordType.water)
                        const SizedBox(height: 14),
                      if (_supportsReminder) ...[
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Set a reminder', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          value: _reminderEnabled,
                          onChanged: (value) => setState(() {
                            _reminderEnabled = value;
                            _reminderAt ??= _startAt ?? DateTime(_date.year, _date.month, _date.day, 9);
                          }),
                        ),
                        if (_reminderEnabled)
                          _dateTimeRow('Reminder time', _reminderAt ?? DateTime.now(), () => _pickReminder()),
                      ],
                      if (_type == RecordType.habit) ...[
                        const SizedBox(height: 8),
                        Text(_tr('Habits stay in your library when paused. Resume them whenever you are ready.'),
                            style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4)),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: AppColors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_tr(_isEditing ? 'Save changes' : 'Save ${_label(_type)}')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _supportsReminder => _type == RecordType.task || _type == RecordType.habit || _type == RecordType.event;

  Widget _numberStepper(String label, int value, int min, int max, ValueChanged<int> onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: Text(_tr(label), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          IconButton(onPressed: value - (min == 1 ? 1 : min == 5 ? 5 : min == 50 ? 50 : 250) >= min ? () => onChanged(value - (min == 1 ? 1 : min == 5 ? 5 : min == 50 ? 50 : 250)) : null, icon: const Icon(Icons.remove_circle_outline)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(onPressed: value + (min == 1 ? 1 : min == 5 ? 5 : min == 50 ? 50 : 250) <= max ? () => onChanged(value + (min == 1 ? 1 : min == 5 ? 5 : min == 50 ? 50 : 250)) : null, icon: const Icon(Icons.add_circle_outline)),
        ]),
      );

  Widget _dateRow(String label, DateTime date, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(15)),
            child: Row(children: [const Icon(Icons.calendar_today_rounded, size: 17, color: AppColors.blue), const SizedBox(width: 11), Expanded(child: Text(_tr(label), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))), Text(shortDate(date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]),
          ),
        ),
      );

  Widget _dateTimeRow(String label, DateTime time, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              const Icon(Icons.notifications_active_outlined, size: 17, color: AppColors.blue),
              const SizedBox(width: 11),
              Expanded(child: Text(_tr(label), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              Text('${shortDate(time)} · ${timeLabel(time)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );

  Widget _timeRow(String label, DateTime? time, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(15)),
            child: Row(children: [const Icon(Icons.schedule_rounded, size: 17, color: AppColors.blue), const SizedBox(width: 11), Expanded(child: Text(_tr(label), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))), Text(time == null ? _tr('Set time') : timeLabel(time), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]),
          ),
        ),
      );

  Future<void> _pickDate() async {
    final value = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (value != null) setState(() {
      _date = dateOnly(value);
      if (_startAt != null) _startAt = DateTime(_date.year, _date.month, _date.day, _startAt!.hour, _startAt!.minute);
      if (_endAt != null) _endAt = DateTime(_date.year, _date.month, _date.day, _endAt!.hour, _endAt!.minute);
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final previous = start ? _startAt : _endAt;
    final value = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(previous ?? DateTime.now()));
    if (value == null) return;
    var updated = DateTime(_date.year, _date.month, _date.day, value.hour, value.minute);
    if (!start && _type == RecordType.sleep && _startAt != null && !updated.isAfter(_startAt!)) {
      updated = updated.add(const Duration(days: 1));
    }
    setState(() {
      if (start) {
        _startAt = updated;
        if (_type == RecordType.event && (_endAt == null || !_endAt!.isAfter(updated))) _endAt = updated.add(const Duration(hours: 1));
      } else {
        _endAt = updated;
      }
    });
  }

  Future<void> _pickReminder() async {
    final initial = _reminderAt ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime.now(), lastDate: DateTime(2100));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    setState(() => _reminderAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final title = switch (_type) {
        RecordType.water => 'Water intake',
        RecordType.sleep => 'Sleep',
        RecordType.mood => _mood,
        _ => _title.text.trim(),
      };
      final meta = Map<String, dynamic>.from(widget.record?.meta ?? {});
      if (_type == RecordType.task) meta['priority'] = _priority;
      if (_type == RecordType.habit) {
        meta['frequency'] = _frequency;
        meta['weekdays'] = _frequency == 'Daily' ? [1, 2, 3, 4, 5, 6, 7] : (_weekdays.toList()..sort());
        meta['target'] = _habitTarget;
        meta['icon'] = _habitIcon;
        meta['color'] = _habitColor;
        meta.putIfAbsent('paused', () => false);
      }
      if (_type == RecordType.event) {
        meta['category'] = _category;
        meta['recurrence'] = _recurrence;
      }
      if (_type == RecordType.water) {
        meta['ml'] = _ml;
        meta['targetMl'] = _targetMl;
      }
      if (_type == RecordType.exercise) meta['minutes'] = _minutes;
      if (_type == RecordType.mood) meta['mood'] = _mood;
      if (_reminderEnabled && _reminderAt != null) {
        meta['reminderAt'] = _reminderAt!.toIso8601String();
      } else {
        meta.remove('reminderAt');
      }
      if (_isEditing) {
        final current = widget.record!;
        await widget.controller.updateRecord(current.copyWith(
          title: title,
          body: _body.text,
          date: _date,
          startAt: _startAt,
          endAt: _endAt,
          meta: meta,
          clearStartAt: _startAt == null,
          clearEndAt: _endAt == null,
        ));
      } else {
        await widget.controller.createRecord(
          type: _type,
          title: title,
          body: _body.text,
          date: _date,
          startAt: _startAt,
          endAt: _endAt,
          meta: meta,
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _label(String type) => switch (type) {
        RecordType.task => 'task', RecordType.habit => 'habit', RecordType.event => 'event',
        RecordType.note => 'note', RecordType.dateNote => 'date note', RecordType.journal => 'journal',
        RecordType.water => 'water entry', RecordType.exercise => 'exercise', RecordType.sleep => 'sleep log',
        RecordType.mood => 'mood entry', _ => 'entry',
      };

  String _defaultTitle(String type) => switch (type) {
        RecordType.habit => 'New habit', RecordType.event => 'New event', RecordType.task => '',
        RecordType.note => '', RecordType.dateNote => '', RecordType.journal => 'My journal',
        RecordType.exercise => 'Exercise', RecordType.water => 'Water intake',
        RecordType.sleep => 'Sleep', RecordType.mood => 'Good', _ => '',
      };

  String _moodLabel(String value) => switch (value) {
        'Amazing' => '😄 ${_tr('Amazing')}', 'Good' => '🙂 ${_tr('Good')}', 'Okay' => '😐 ${_tr('Okay')}',
        'Low' => '😔 ${_tr('Low')}', 'Stressed' => '😣 ${_tr('Stressed')}', _ => _tr(value),
      };
}

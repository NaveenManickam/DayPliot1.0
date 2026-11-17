import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/app_record.dart';
import '../providers/app_controller.dart';
import '../utils/date_helpers.dart';
import '../widgets/record_editor.dart';
import '../widgets/record_tile.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _cursor = dateOnly(DateTime.now());
  DateTime _selected = dateOnly(DateTime.now());
  String _view = 'Month';

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final strings = [
      ('Month', 'monthly'), ('Week', 'weekly'), ('Day', 'daily'), ('Agenda', 'agenda'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 118),
      children: [
        Row(children: [
          Expanded(child: Text('My Planner', style: Theme.of(context).textTheme.headlineSmall)),
          FilledButton.icon(
            onPressed: () => showRecordEditor(context, controller, type: RecordType.task, initialDate: _selected),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Task', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(backgroundColor: AppColors.blue, padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10)),
          ),
        ]),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            for (final item in strings)
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _view = item.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: _view == item.$1 ? AppColors.blue : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                  child: Text(item.$1, textAlign: TextAlign.center, style: TextStyle(color: _view == item.$1 ? Colors.white : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              )),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          IconButton(onPressed: _previous, icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(child: Text(_view == 'Day' ? shortDate(_selected) : monthHeading(_cursor), textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink))),
          TextButton(onPressed: () => setState(() { _cursor = dateOnly(DateTime.now()); _selected = dateOnly(DateTime.now()); }), child: const Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
          IconButton(onPressed: _next, icon: const Icon(Icons.chevron_right_rounded)),
        ]),
        if (_view == 'Month') _buildMonthGrid(controller),
        if (_view == 'Week') _buildWeekStrip(controller),
        if (_view == 'Day') _buildDayTimeline(controller),
        if (_view == 'Agenda') _buildAgenda(controller),
        if (_view != 'Agenda') ...[
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Text(shortDate(_selected), style: Theme.of(context).textTheme.titleLarge)),
            _SmallAction(icon: Icons.add_task_rounded, label: 'Task', onTap: () => showRecordEditor(context, controller, type: RecordType.task, initialDate: _selected)),
            const SizedBox(width: 5),
            _SmallAction(icon: Icons.event_rounded, label: 'Event', onTap: () => showRecordEditor(context, controller, type: RecordType.event, initialDate: _selected)),
          ]),
          const SizedBox(height: 11),
          _buildSelectedDateItems(controller),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showRecordEditor(context, controller, type: RecordType.dateNote, initialDate: _selected),
            icon: const Icon(Icons.sticky_note_2_outlined, size: 17),
            label: const Text('Add a note to this date'),
          ),
        ],
      ],
    );
  }

  Widget _buildMonthGrid(AppController controller) {
    final days = monthGrid(_cursor);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(22)),
      child: Column(children: [
        Row(children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700))))).toList()),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 2),
          itemBuilder: (context, index) {
            final date = days[index];
            final inMonth = date.month == _cursor.month;
            final selected = sameDate(date, _selected);
            final entries = controller.recordsForDate(date);
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selected = dateOnly(date)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(color: selected ? AppColors.blue : Colors.transparent, borderRadius: BorderRadius.circular(13)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${date.day}', style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? Colors.white : (inMonth ? AppColors.ink : AppColors.muted.withValues(alpha: .55)))),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: _indicators(entries, selected)),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }

  List<Widget> _indicators(List<AppRecord> entries, bool selected) {
    final types = <String>{};
    for (final record in entries) {
      if (record.type == RecordType.task) types.add('task');
      if (record.type == RecordType.event) types.add('event');
      if (record.type == RecordType.dateNote) types.add('note');
    }
    return [
      if (types.contains('task')) _dot(selected ? Colors.white : AppColors.coral),
      if (types.contains('event')) _dot(selected ? Colors.white : AppColors.mint),
      if (types.contains('note')) _dot(selected ? Colors.white : AppColors.yellow),
    ];
  }

  Widget _dot(Color color) => Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _buildWeekStrip(AppController controller) {
    final days = weekDays(_selected);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(22)),
      child: Row(children: days.map((date) {
        final selected = sameDate(date, _selected);
        final hasContent = controller.recordsForDate(date).isNotEmpty;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() { _selected = date; _cursor = date; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: selected ? AppColors.blue : Colors.transparent, borderRadius: BorderRadius.circular(15)),
            child: Column(children: [
              Text(DateFormatE.weekday(date), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: selected ? Colors.white70 : AppColors.muted)),
              const SizedBox(height: 7),
              Text('${date.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.ink)),
              const SizedBox(height: 6),
              if (hasContent) _dot(selected ? Colors.white : AppColors.coral) else const SizedBox(height: 4),
            ]),
          ),
        ));
      }).toList()),
    );
  }

  Widget _buildDayTimeline(AppController controller) {
    final entries = controller.recordsForDate(_selected, types: {RecordType.task, RecordType.event});
    final notes = controller.recordsForDate(_selected, types: {RecordType.dateNote});
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildWeekStrip(controller),
      const SizedBox(height: 13),
      if (entries.isEmpty && notes.isEmpty)
        _emptyDay()
      else ...[
        ...entries.map((record) => RecordTile(record: record, compact: true,
          onTap: () => showRecordEditor(context, controller, type: record.type, record: record),
          onToggle: record.type == RecordType.task ? () => controller.toggleTask(record) : record.type == RecordType.event ? () => controller.updateRecord(record.copyWith(done: !record.done)) : null)),
        ...notes.map((record) => _DateNoteCard(record: record, onTap: () => showRecordEditor(context, controller, type: RecordType.dateNote, record: record))),
      ],
    ]);
  }

  Widget _buildAgenda(AppController controller) {
    final start = dateOnly(_selected);
    final items = <Widget>[];
    for (var i = 0; i < 14; i++) {
      final date = start.add(Duration(days: i));
      final records = controller.recordsForDate(date, types: {RecordType.task, RecordType.event, RecordType.dateNote});
      if (records.isEmpty) continue;
      items.add(Padding(padding: const EdgeInsets.only(top: 14, bottom: 8), child: Text(shortDate(date), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink))));
      items.addAll(records.map((record) => RecordTile(record: record, compact: true,
        onTap: () => showRecordEditor(context, controller, type: record.type, record: record),
        onToggle: record.type == RecordType.task ? () => controller.toggleTask(record) : record.type == RecordType.event ? () => controller.updateRecord(record.copyWith(done: !record.done)) : null)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items.isEmpty ? [_emptyDay()] : items);
  }

  Widget _buildSelectedDateItems(AppController controller) {
    final records = controller.recordsForDate(_selected, types: {RecordType.task, RecordType.event, RecordType.dateNote});
    if (records.isEmpty) return _emptyDay();
    return Column(children: records.map((record) {
      if (record.type == RecordType.dateNote) return _DateNoteCard(record: record, onTap: () => showRecordEditor(context, controller, type: RecordType.dateNote, record: record));
      return RecordTile(record: record, compact: true,
        onTap: () => showRecordEditor(context, controller, type: record.type, record: record),
        onToggle: record.type == RecordType.task ? () => controller.toggleTask(record) : record.type == RecordType.event ? () => controller.updateRecord(record.copyWith(done: !record.done)) : null);
    }).toList());
  }

  Widget _emptyDay() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(18)),
        child: const Center(child: Column(children: [Icon(Icons.event_available_rounded, color: AppColors.blue, size: 26), SizedBox(height: 8), Text('Nothing planned yet', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 4), Text('Add a task, event or date note.', style: TextStyle(fontSize: 11, color: AppColors.muted))])),
      );

  void _previous() => setState(() {
        if (_view == 'Day') { _selected = _selected.subtract(const Duration(days: 1)); _cursor = _selected; }
        else if (_view == 'Week') { _selected = _selected.subtract(const Duration(days: 7)); _cursor = _selected; }
        else if (_view == 'Agenda') { _selected = _selected.subtract(const Duration(days: 14)); _cursor = _selected; }
        else { _cursor = DateTime(_cursor.year, _cursor.month - 1, 1); _selected = DateTime(_cursor.year, _cursor.month, 1); }
      });

  void _next() => setState(() {
        if (_view == 'Day') { _selected = _selected.add(const Duration(days: 1)); _cursor = _selected; }
        else if (_view == 'Week') { _selected = _selected.add(const Duration(days: 7)); _cursor = _selected; }
        else if (_view == 'Agenda') { _selected = _selected.add(const Duration(days: 14)); _cursor = _selected; }
        else { _cursor = DateTime(_cursor.year, _cursor.month + 1, 1); _selected = DateTime(_cursor.year, _cursor.month, 1); }
      });
}

class DateFormatE {
  static String weekday(DateTime date) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
}

class _DateNoteCard extends StatelessWidget {
  const _DateNoteCard({required this.record, required this.onTap});
  final AppRecord record;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          leading: const CircleAvatar(backgroundColor: AppColors.yellowPale, child: Icon(Icons.sticky_note_2_rounded, color: AppColors.yellow)),
          title: Text(record.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: Text(record.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ),
      );
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7), child: Row(children: [Icon(icon, size: 15, color: AppColors.blue), const SizedBox(width: 3), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.blue, fontWeight: FontWeight.w700))])));
}

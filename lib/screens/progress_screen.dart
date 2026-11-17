import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/app_record.dart';
import '../providers/app_controller.dart';
import '../utils/date_helpers.dart';
import '../widgets/record_editor.dart';
import '../utils/app_strings.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _period = 'Week';

  @override
  Widget build(BuildContext context) {
    final now = dateOnly(DateTime.now());
    final range = _range(now);
    final tasks = widget.controller.recordsOf(RecordType.task).where((r) => !r.date.isBefore(range.$1) && !r.date.isAfter(range.$2)).toList();
    final completed = tasks.where((r) => r.done).length;
    final pending = tasks.length - completed;
    final percent = tasks.isEmpty ? 0 : completed / tasks.length;
    final habitChecks = widget.controller.recordsOf(RecordType.habitCheck).where((r) => !r.date.isBefore(range.$1) && !r.date.isAfter(range.$2)).length;
    final habits = widget.controller.allHabits;
    final expected = widget.controller.expectedHabitDaysForRange(habits, range.$1, range.$2);
    final habitPercent = expected == 0 ? 0.0 : (habitChecks / expected).clamp(0, 1).toDouble();
    final totalWater = _sumForRange(RecordType.water, range.$1, range.$2, 'ml');
    final exerciseMinutes = _sumForRange(RecordType.exercise, range.$1, range.$2, 'minutes');
    final longestStreaks = habits.map(widget.controller.longestHabitStreak).toList();
    final bestStreak = longestStreaks.isEmpty ? 0 : longestStreaks.reduce((a, b) => a > b ? a : b);
    final values = _chartValues(now);
    final sleepRecords = widget.controller.recordsOf(RecordType.sleep)
        .where((r) => !r.date.isBefore(range.$1) && !r.date.isAfter(range.$2))
        .toList();
    final moodRecords = widget.controller.recordsOf(RecordType.mood)
        .where((r) => !r.date.isBefore(range.$1) && !r.date.isAfter(range.$2))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 118),
      children: [
        Text(context.dp('My Progress'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(15)),
          child: Row(children: ['Day', 'Week', 'Month', 'Year'].map((period) => Expanded(child: GestureDetector(
            onTap: () => setState(() => _period = period),
            child: AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: _period == period ? AppColors.blue : Colors.transparent, borderRadius: BorderRadius.circular(12)),
              child: Text(context.dp(period), textAlign: TextAlign.center, style: TextStyle(color: _period == period ? Colors.white : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700))),
          ))).toList()),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(23), boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: .24), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.dp('TASK COMPLETION'), style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text('${(percent * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('$completed completed out of ${tasks.length} tasks', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ])),
            SizedBox(width: 78, height: 78, child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(value: percent.toDouble(), strokeWidth: 7, backgroundColor: Colors.white24, color: Colors.white)),
              const Icon(Icons.flag_rounded, color: Colors.white, size: 27),
            ])),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _StatCard(label: 'Completed', value: '$completed', icon: Icons.check_circle_rounded, color: AppColors.mint, pale: AppColors.mintPale)),
          const SizedBox(width: 9),
          Expanded(child: _StatCard(label: 'Pending', value: '$pending', icon: Icons.pending_actions_rounded, color: AppColors.coral, pale: AppColors.coralPale)),
          const SizedBox(width: 9),
          Expanded(child: _StatCard(label: 'Best streak', value: '$bestStreak d', icon: Icons.local_fire_department_rounded, color: AppColors.yellow, pale: AppColors.yellowPale)),
        ]),
        const SizedBox(height: 21),
        Text(context.dp('Productivity history'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(22)),
          child: Column(children: [
            SizedBox(height: 154, child: CustomPaint(size: Size.infinite, painter: _BarChartPainter(values: values, dark: Theme.of(context).brightness == Brightness.dark))),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle)), const SizedBox(width: 6), const Text(context.dp('Tasks completed'), style: TextStyle(fontSize: 10, color: AppColors.muted))]),
          ]),
        ),
        const SizedBox(height: 21),
        Text(context.dp('Habit consistency'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(21)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text('${(habitPercent * 100).round()}% completed', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))), Text('$habitChecks / $expected', style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700))]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: habitPercent, minHeight: 8, color: AppColors.mint, backgroundColor: AppColors.mintPale)),
            const SizedBox(height: 13),
            if (habits.isEmpty) const Text('Add habits to start measuring consistency.', style: TextStyle(color: AppColors.muted, fontSize: 11))
            else ...habits.map((habit) => Padding(padding: const EdgeInsets.only(top: 7), child: Row(children: [Expanded(child: Text(habit.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))), Text('${widget.controller.habitStreak(habit)} day streak', style: const TextStyle(color: AppColors.muted, fontSize: 10))]))),
          ]),
        ),
        const SizedBox(height: 21),
        Text(context.dp('Activity heatmap'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _Heatmap(controller: widget.controller),
        const SizedBox(height: 21),
        Text(context.dp('Personal tracking'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard(label: 'Water logged', value: '${(totalWater / 1000).toStringAsFixed(1)} L', icon: Icons.water_drop_rounded, color: AppColors.blue, pale: AppColors.bluePale)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(label: 'Exercise', value: '$exerciseMinutes min', icon: Icons.fitness_center_rounded, color: AppColors.mint, pale: AppColors.mintPale)),
        ]),
        const SizedBox(height: 21),
        Text(context.dp('Sleep & mood trends'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _WellnessTrends(
          sleepRecords: sleepRecords,
          moodRecords: moodRecords,
          today: now,
        ),
        const SizedBox(height: 18),
        Text(context.dp('Sleep & mood history'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        _HistoryPanel(
          controller: widget.controller,
          type: RecordType.sleep,
          title: 'Sleep logs',
          empty: 'No sleep entries yet.',
        ),
        const SizedBox(height: 9),
        _HistoryPanel(
          controller: widget.controller,
          type: RecordType.mood,
          title: 'Mood check-ins',
          empty: 'No mood entries yet.',
        ),
        const SizedBox(height: 9),
        _HistoryPanel(
          controller: widget.controller,
          type: RecordType.journal,
          title: 'Journal entries',
          empty: 'No journal entries yet.',
        ),
        const SizedBox(height: 10),
        Text(context.dp('Statistics are calculated from entries saved on this device. Empty periods remain zero.'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted, fontSize: 10)),
      ],
    );
  }

  (DateTime, DateTime) _range(DateTime now) {
    if (_period == 'Day') return (now, now);
    if (_period == 'Week') {
      final start = now.subtract(Duration(days: (now.weekday + 6) % 7));
      return (start, now);
    }
    if (_period == 'Month') {
      final start = DateTime(now.year, now.month, 1);
      return (start, now);
    }
    return (DateTime(now.year, 1, 1), now);
  }

  int _sumForRange(String type, DateTime start, DateTime end, String metaKey) => widget.controller.recordsOf(type)
      .where((r) => !r.date.isBefore(start) && !r.date.isAfter(end))
      .fold(0, (sum, record) => sum + ((record.meta[metaKey] as num?)?.toInt() ?? 0));

  List<int> _chartValues(DateTime now) {
    if (_period == 'Year') {
      return List.generate(12, (index) {
        final month = index + 1;
        return widget.controller.recordsOf(RecordType.task).where((r) => r.done && r.date.year == now.year && r.date.month == month && !r.date.isAfter(now)).length;
      });
    }
    if (_period == 'Month') {
      return List.generate(7, (index) {
        final start = DateTime(now.year, now.month, 1).add(Duration(days: index * 5));
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        final bucketEnd = start.add(const Duration(days: 4));
        final end = bucketEnd.isAfter(monthEnd) ? monthEnd : bucketEnd;
        return widget.controller.recordsOf(RecordType.task).where((r) => r.done && !r.date.isBefore(start) && !r.date.isAfter(end) && !r.date.isAfter(now)).length;
      });
    }
    final count = _period == 'Day' ? 1 : 7;
    return List.generate(count, (index) {
      final date = _period == 'Day' ? now : now.subtract(Duration(days: count - index - 1));
      return widget.controller.recordsForDate(date, types: {RecordType.task}).where((r) => r.done).length;
    });
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.controller,
    required this.type,
    required this.title,
    required this.empty,
  });

  final AppController controller;
  final String type;
  final String title;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final records = controller.recordsOf(type).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = records.take(3).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 12, 10, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.dp(title), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(context.dp(empty), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          )
        else
          ...recent.map((record) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  type == RecordType.sleep
                      ? Icons.bedtime_rounded
                      : type == RecordType.mood
                          ? Icons.mood_rounded
                          : Icons.menu_book_rounded,
                  color: AppColors.blue,
                  size: 19,
                ),
                title: Text(
                  context.dp(_recordTitle(record)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _recordSubtitle(record),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: AppColors.muted),
                ),
                trailing: const Icon(Icons.edit_outlined, size: 16, color: AppColors.muted),
                onTap: () => showRecordEditor(
                  context,
                  controller,
                  type: type,
                  record: record,
                ),
              )),
      ]),
    );
  }

  String _recordTitle(AppRecord record) {
    if (type == RecordType.sleep) return 'Sleep';
    if (type == RecordType.mood) return record.meta['mood'] as String? ?? record.title;
    return record.title.isEmpty ? 'Journal entry' : record.title;
  }

  String _recordSubtitle(AppRecord record) {
    final date = '${record.date.day}/${record.date.month}/${record.date.year}';
    if (type == RecordType.sleep && record.startAt != null && record.endAt != null) {
      final end = record.endAt!;
      final start = record.startAt!;
      final duration = end.difference(start);
      final adjusted = duration.isNegative ? duration + const Duration(days: 1) : duration;
      final hours = adjusted.inHours;
      final minutes = adjusted.inMinutes.remainder(60);
      return '$date · $hours h $minutes min';
    }
    final content = record.body.trim();
    if (content.isEmpty) return date;
    return '$date · $content';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.pale});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color pale;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: pale, shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.muted)),
        ]),
      );
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.values, required this.dark});
  final List<int> values;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxValue == 0 ? 1.0 : maxValue.toDouble();
    final baseY = size.height - 20;
    final gridPaint = Paint()..color = (dark ? Colors.white : AppColors.line).withValues(alpha: .6)..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = 12 + i * (baseY - 12) / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final width = size.width / (values.length * 1.65);
    for (var i = 0; i < values.length; i++) {
      final x = (i + .5) * size.width / values.length - width / 2;
      final height = (values[i] / maxY) * (baseY - 22);
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, baseY - height, width, height.clamp(3.0, baseY).toDouble()), const Radius.circular(7));
      canvas.drawRRect(rect, Paint()..color = AppColors.blue.withValues(alpha: .88));
    }
  }
  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => oldDelegate.values != values || oldDelegate.dark != dark;
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final end = dateOnly(DateTime.now());
    final start = end.subtract(const Duration(days: 181));
    final activity = <String, int>{};
    for (final record in controller.records) {
      if (record.date.isBefore(start) || record.date.isAfter(end)) continue;
      if (record.type == RecordType.task && record.done || record.type == RecordType.habitCheck) {
        final key = dayKey(record.date);
        activity[key] = (activity[key] ?? 0) + 1;
      }
    }
    final first = start.subtract(Duration(days: (start.weekday + 6) % 7));
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(19)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 4, runSpacing: 4, children: List.generate(26 * 7, (index) {
          final date = first.add(Duration(days: index));
          final count = activity[dayKey(date)] ?? 0;
          final color = count == 0 ? AppColors.line : count == 1 ? const Color(0xFFC9D0FF) : count < 4 ? const Color(0xFF8E9AFF) : AppColors.blue;
          return Container(width: 9, height: 9, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
        })),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          const Text('Less', style: TextStyle(fontSize: 9, color: AppColors.muted)),
          const SizedBox(width: 5),
          for (final color in [AppColors.line, const Color(0xFFC9D0FF), const Color(0xFF8E9AFF), AppColors.blue])
            Container(width: 9, height: 9, margin: const EdgeInsets.only(right: 3), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const Text('More', style: TextStyle(fontSize: 9, color: AppColors.muted)),
        ]),
      ]),
    );
  }
}
class _WellnessTrends extends StatelessWidget {
  const _WellnessTrends({
    required this.sleepRecords,
    required this.moodRecords,
    required this.today,
  });

  final List<AppRecord> sleepRecords;
  final List<AppRecord> moodRecords;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final validSleep = sleepRecords.where((r) => r.startAt != null && r.endAt != null).toList();
    final sleepHours = <double>[];
    final moodScores = <double>[];
    final moodValues = moodRecords
        .map((r) => _moodScore(r.meta['mood'] as String? ?? r.title))
        .whereType<int>()
        .toList();
    for (var offset = 6; offset >= 0; offset--) {
      final day = today.subtract(Duration(days: offset));
      final nights = validSleep.where((r) =>
          r.date.year == day.year && r.date.month == day.month && r.date.day == day.day);
      final durations = nights.map((r) {
        var duration = r.endAt!.difference(r.startAt!);
        if (duration.isNegative) duration += const Duration(days: 1);
        return duration.inMinutes / 60;
      }).toList();
      sleepHours.add(durations.isEmpty
          ? 0
          : durations.reduce((a, b) => a + b) / durations.length);

      final dayMoods = moodRecords.where((r) =>
          r.date.year == day.year && r.date.month == day.month && r.date.day == day.day);
      final scores = dayMoods
          .map((r) => _moodScore(r.meta['mood'] as String? ?? r.title))
          .whereType<int>()
          .toList();
      moodScores.add(scores.isEmpty
          ? 0
          : scores.reduce((a, b) => a + b) / scores.length);
    }
    final averageSleep = validSleep.isEmpty
        ? 0.0
        : validSleep.map((r) {
            var duration = r.endAt!.difference(r.startAt!);
            if (duration.isNegative) duration += const Duration(days: 1);
            return duration.inMinutes / 60;
          }).reduce((a, b) => a + b) / validSleep.length;
    final averageMood = moodValues.isEmpty
        ? 0.0
        : moodValues.reduce((a, b) => a + b) / moodValues.length;

    return Column(children: [
      _TrendCard(
        title: 'Sleep duration',
        value: validSleep.isEmpty ? '—' : '${averageSleep.toStringAsFixed(1)} h',
        subtitle: '${validSleep.length} sleep logs in this period',
        values: sleepHours,
        maximum: 12,
        color: AppColors.blue,
      ),
      const SizedBox(height: 10),
      _TrendCard(
        title: 'Mood score',
        value: moodValues.isEmpty ? '—' : '${averageMood.toStringAsFixed(1)} / 5',
        subtitle: '${moodValues.length} mood check-ins in this period',
        values: moodScores,
        maximum: 5,
        color: AppColors.coral,
      ),
      if (moodValues.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final entry in _moodCounts(moodRecords).entries)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${entry.key} · ${entry.value}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      ],
    ]);
  }

  int? _moodScore(String mood) => switch (mood.toLowerCase()) {
        'amazing' => 5,
        'good' => 4,
        'okay' => 3,
        'low' => 2,
        'stressed' => 1,
        _ => null,
      };

  Map<String, int> _moodCounts(List<AppRecord> records) {
    final result = <String, int>{};
    for (final record in records) {
      final mood = record.meta['mood'] as String? ?? record.title;
      if (_moodScore(mood) != null) result[mood] = (result[mood] ?? 0) + 1;
    }
    return result;
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.values,
    required this.maximum,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final List<double> values;
  final double maximum;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 2),
          Text(context.dp(subtitle), style: const TextStyle(color: AppColors.muted, fontSize: 9)),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: CustomPaint(painter: _WellnessBarPainter(values: values, maximum: maximum, color: color)),
          ),
          const SizedBox(height: 5),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('6d ago', style: TextStyle(fontSize: 8, color: AppColors.muted)),
              Text('5d', style: TextStyle(fontSize: 8, color: AppColors.muted)),
              Text('4d', style: TextStyle(fontSize: 8, color: AppColors.muted)),
              Text('3d', style: TextStyle(fontSize: 8, color: AppColors.muted)),
              Text('2d', style: TextStyle(fontSize: 8, color: AppColors.muted)),
              Text('Yesterday', style: TextStyle(fontSize: 8, color: AppColors.muted)),
              Text('Today', style: TextStyle(fontSize: 8, color: AppColors.muted)),
            ],
          ),
        ]),
      );
}

class _WellnessBarPainter extends CustomPainter {
  _WellnessBarPainter({required this.values, required this.maximum, required this.color});

  final List<double> values;
  final double maximum;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final slot = size.width / values.length;
    final barWidth = slot * .48;
    for (var index = 0; index < values.length; index++) {
      final value = values[index].clamp(0, maximum);
      final height = value == 0 ? 2.0 : (value / maximum) * (size.height - 4);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          slot * index + (slot - barWidth) / 2,
          size.height - height,
          barWidth,
          height,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: value == 0 ? .12 : .85));
    }
  }

  @override
  bool shouldRepaint(covariant _WellnessBarPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.maximum != maximum || oldDelegate.color != color;
}


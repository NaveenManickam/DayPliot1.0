import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/app_record.dart';
import '../providers/app_controller.dart';
import '../widgets/record_editor.dart';
import '../widgets/record_tile.dart';
import '../widgets/section_title.dart';
import '../utils/app_strings.dart';

class MyDayScreen extends StatefulWidget {
  const MyDayScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<MyDayScreen> createState() => _MyDayScreenState();
}

class _MyDayScreenState extends State<MyDayScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final tasks = controller.todayTasks.where((task) => task.title.toLowerCase().contains(_search.toLowerCase())).toList();
    tasks.sort((a, b) {
      final aOrder = a.meta['order'] as int? ?? 999999;
      final bOrder = b.meta['order'] as int? ?? 999999;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return (a.startAt ?? a.date).compareTo(b.startAt ?? b.date);
    });
    final total = controller.todayTasks.length;
    final done = controller.completedToday;
    final progress = total == 0 ? 0.0 : done / total;
    final habits = controller.allHabits;
    final water = controller.waterMlFor(DateTime.now());
    final target = controller.waterTargetMlFor(DateTime.now());
    final exercise = controller.exerciseMinutesFor(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 118),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${AppStrings.translate(controller.greeting, controller.language)}${controller.name.isEmpty ? '' : ', ${controller.name}'}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            Text(controller.language == 'Tamil' ? 'இந்த மாதம் ${controller.monthTaskCount} பணிகள் 👏' : 'You have ${controller.monthTaskCount} tasks\nthis month 👏',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.18, fontSize: 22)),
          ])),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.yellowPale, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.waving_hand_rounded, color: Color(0xFFDDAB3F), size: 23),
          ),
        ]),
        const SizedBox(height: 18),
        TextField(
          onChanged: (value) => setState(() => _search = value),
          decoration: InputDecoration(
            hintText: context.dp('Search a task...'),
            prefixIcon: Icon(Icons.search_rounded, size: 19),
            suffixIcon: Icon(Icons.tune_rounded, size: 18),
          ),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _MetricBubble(label: context.dp('To-do'), value: '${controller.pendingToday}', icon: Icons.assignment_turned_in_rounded, color: AppColors.coral, pale: AppColors.coralPale)),
          const SizedBox(width: 10),
          Expanded(child: _MetricBubble(label: context.dp('Progress'), value: '${(progress * 100).round()}%', icon: Icons.trending_up_rounded, color: AppColors.yellow, pale: AppColors.yellowPale, progress: progress)),
          const SizedBox(width: 10),
          Expanded(child: _MetricBubble(label: context.dp('Done'), value: '$done', icon: Icons.check_circle_rounded, color: AppColors.mint, pale: AppColors.mintPale)),
        ]),
        SectionTitle(context.dp('Today’s Tasks'), action: context.dp('Reorder'), onAction: () => _showAllTasks(context)),
        if (tasks.isEmpty)
          _EmptyCard(title: _search.isEmpty ? context.dp('A clear day ahead') : context.dp('No matching tasks'), subtitle: _search.isEmpty ? context.dp('Add a task when something needs your attention.') : context.dp('Try another search phrase.'), icon: Icons.check_circle_outline_rounded)
        else
          SizedBox(
            height: 174,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => SizedBox(
                width: 246,
                child: RecordTile(
                  record: tasks[index],
                  onToggle: () => controller.toggleTask(tasks[index]),
                  onTap: () => showRecordEditor(context, controller, type: RecordType.task, record: tasks[index]),
                ),
              ),
            ),
          ),
        SectionTitle(context.dp('Your Habits'), action: context.dp('Add habit'), onAction: () => showRecordEditor(context, controller, type: RecordType.habit)),
        if (habits.isEmpty)
          _EmptyCard(title: context.dp('Build a small routine'), subtitle: context.dp('Track a habit and grow your streak one day at a time.'), icon: Icons.local_fire_department_rounded)
        else
          ...habits.map((habit) => _HabitRow(
                habit: habit,
                done: controller.habitDoneToday(habit),
                streak: controller.habitStreak(habit),
                missed: controller.habitMissedDays(habit),
                paused: habit.meta['paused'] == true,
                onToggle: () => controller.toggleHabit(habit),
                onTap: () => showRecordEditor(context, controller, type: RecordType.habit, record: habit),
                onPause: () => controller.toggleHabitPause(habit),
              )),
        SectionTitle(context.dp('Today at a glance')),
        Row(children: [
          Expanded(child: _MiniSummary(icon: Icons.water_drop_rounded, title: context.dp('Water'), value: '$water / $target ml', progress: target == 0 ? 0 : (water / target).clamp(0, 1).toDouble(), color: AppColors.blue,
            onTap: () => showRecordEditor(context, controller, type: RecordType.water))),
          const SizedBox(width: 10),
          Expanded(child: _MiniSummary(icon: Icons.fitness_center_rounded, title: context.dp('Exercise'), value: '$exercise min', progress: (exercise / 60).clamp(0, 1).toDouble(), color: AppColors.mint,
            onTap: () => showRecordEditor(context, controller, type: RecordType.exercise))),
        ]),
        const SizedBox(height: 14),
        _QuoteCard(quote: controller.todayQuote),
      ],
    );
  }

  void _showAllTasks(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(context.dp('Today’s tasks'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              Expanded(child: ReorderableListView.builder(
                itemCount: widget.controller.todayTasks.length,
                onReorder: (oldIndex, newIndex) => widget.controller.reorderTasks(DateTime.now(), oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final task = widget.controller.todayTasks..sort((a, b) => (a.meta['order'] as int? ?? 999999).compareTo(b.meta['order'] as int? ?? 999999));
                  final item = task[index];
                  return Padding(
                    key: ValueKey(item.id),
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(children: [
                      const Icon(Icons.drag_handle_rounded, color: AppColors.muted),
                      Expanded(child: RecordTile(
                        record: item, compact: true,
                        onToggle: () => widget.controller.toggleTask(item),
                        onTap: () => showRecordEditor(context, widget.controller, type: RecordType.task, record: item),
                      )),
                    ]),
                  );
                },
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

class _MetricBubble extends StatelessWidget {
  const _MetricBubble({required this.label, required this.value, required this.icon, required this.color, required this.pale, this.progress});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color pale;
  final double? progress;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(19), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .035), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Column(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: pale, shape: BoxShape.circle), child: Icon(icon, color: color, size: 19)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600)),
          if (progress != null) ...[
            const SizedBox(height: 7),
            SizedBox(width: 54, child: LinearProgressIndicator(value: progress, minHeight: 3, borderRadius: BorderRadius.circular(10), backgroundColor: pale, color: color)),
          ],
        ]),
      );
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit, required this.done, required this.streak, required this.missed, required this.paused, required this.onToggle, required this.onTap, required this.onPause});
  final AppRecord habit;
  final bool done;
  final int streak;
  final int missed;
  final bool paused;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          onTap: onTap,
          leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: Color((habit.meta['color'] as int?) ?? 0xFFF2C45E).withValues(alpha: .16), borderRadius: BorderRadius.circular(14)), child: Icon(_habitIcon(habit.meta['icon'] as String?), color: Color((habit.meta['color'] as int?) ?? 0xFFF2C45E))),
          title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: Text(paused ? context.dp('Paused') : '🔥 $streak ${context.dp('day streak')}  ·  $missed ${context.dp('missed')}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            PopupMenuButton<String>(
              tooltip: context.dp('Habit options'),
              onSelected: (_) => onPause(),
              itemBuilder: (_) => [PopupMenuItem(value: 'pause', child: Text(paused ? context.dp('Resume habit') : context.dp('Pause habit')))],
              child: const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
            ),
            IconButton(
              onPressed: paused ? null : onToggle,
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 30, height: 30,
                decoration: BoxDecoration(color: done ? AppColors.mint : AppColors.canvas, shape: BoxShape.circle, border: Border.all(color: done ? AppColors.mint : AppColors.line)),
                child: Icon(Icons.check_rounded, color: done ? Colors.white : AppColors.muted, size: 18),
              ),
            ),
          ]),
        ),
      );

  IconData _habitIcon(String? icon) => switch (icon) {
        'water' => Icons.water_drop_rounded, 'run' => Icons.directions_run_rounded,
        'book' => Icons.menu_book_rounded, 'meditate' => Icons.self_improvement_rounded,
        _ => Icons.local_fire_department_rounded,
      };
}

class _MiniSummary extends StatelessWidget {
  const _MiniSummary({required this.icon, required this.title, required this.value, required this.progress, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final double progress;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(icon, size: 17, color: color), const SizedBox(width: 7), Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))]),
            const SizedBox(height: 9),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 5, color: color, backgroundColor: color.withValues(alpha: .13))),
          ]),
        ),
      );
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final String quote;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.bluePale.withValues(alpha: .75), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Icon(Icons.format_quote_rounded, color: AppColors.blue, size: 28),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.dp('A LITTLE WISDOM'), style: TextStyle(color: AppColors.blue, fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(quote, style: const TextStyle(color: AppColors.ink, fontSize: 12, height: 1.4, fontWeight: FontWeight.w600)),
          ])),
        ]),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [Icon(icon, color: AppColors.blue, size: 25), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11))]))]),
      );
}

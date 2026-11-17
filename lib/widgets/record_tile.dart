import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../models/app_record.dart';
import '../utils/date_helpers.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.record, this.onTap, this.onToggle, this.compact = false});
  final AppRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(record);
    final time = record.startAt == null ? '' : timeLabel(record.startAt!);
    final isCheckable = record.type == RecordType.task || record.type == RecordType.event;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: EdgeInsets.only(bottom: compact ? 8 : 11),
        padding: EdgeInsets.all(compact ? 13 : 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha: .22), blurRadius: 18, offset: const Offset(0, 7))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCheckable && onToggle != null)
              Padding(
                padding: const EdgeInsets.only(right: 11, top: 2),
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: record.done ? Colors.white : Colors.white.withValues(alpha: .18),
                      border: Border.all(color: Colors.white.withValues(alpha: .9), width: 1.4),
                    ),
                    child: record.done ? Icon(Icons.check_rounded, size: 14, color: _strongColor(record)) : null,
                  ),
                ),
              ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Text(
                      record.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: compact ? 13 : 14, fontWeight: FontWeight.w800,
                        decoration: record.done ? TextDecoration.lineThrough : null),
                    ),
                  ),
                  if (time.isNotEmpty) Text(time, style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
                if (record.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(record.body, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: .84), fontSize: 11, height: 1.35)),
                ],
                if (record.type == RecordType.task || record.type == RecordType.event) ...[
                  const SizedBox(height: 9),
                  Row(children: [
                    if (record.meta['priority'] != null)
                      _tinyPill('${record.meta['priority']} priority'),
                    if (record.meta['category'] != null) _tinyPill('${record.meta['category']}'),
                    const Spacer(),
                    if (isCheckable && record.done)
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                  ]),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tinyPill(String text) => Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
      );

  Color _colorFor(AppRecord record) {
    if (record.type == RecordType.task) {
      if (record.done) return const Color(0xFF70BDAA);
      return switch (record.meta['priority'] as String? ?? 'Medium') {
        'High' => AppColors.coral,
        'Low' => const Color(0xFF61B9A7),
        _ => AppColors.blue,
      };
    }
    if (record.type == RecordType.event) return const Color(0xFF8D8BEA);
    return const Color(0xFF6675E9);
  }

  Color _strongColor(AppRecord record) => _colorFor(record);
}

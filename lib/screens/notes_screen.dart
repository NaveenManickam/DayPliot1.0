import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_constants.dart';
import '../models/app_record.dart';
import '../providers/app_controller.dart';
import '../utils/app_strings.dart';
import '../widgets/record_editor.dart';
import '../utils/app_strings.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.controller.language);
    final notes = widget.controller.recordsOf(RecordType.note)
        .where((note) => note.title.toLowerCase().contains(_query.toLowerCase()) || note.body.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 118),
      children: [
        Row(children: [
          Expanded(child: Text(strings.call('notes'), style: Theme.of(context).textTheme.headlineSmall)),
          FilledButton.icon(
            onPressed: () => showRecordEditor(context, widget.controller, type: RecordType.note),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('New note', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(backgroundColor: AppColors.blue, padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10)),
          ),
        ]),
        const SizedBox(height: 17),
        TextField(
          controller: _search,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(hintText: strings.call('search_notes'), prefixIcon: const Icon(Icons.search_rounded, size: 19), suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close_rounded, size: 18))),
        ),
        const SizedBox(height: 17),
        Row(children: [
          Expanded(child: Text('${notes.length} notes', style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700))),
          Text(context.dp('Stored on this device'), style: TextStyle(color: AppColors.muted, fontSize: 10)),
        ]),
        const SizedBox(height: 10),
        if (notes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 25),
            decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(22)),
            child: Column(children: [
              Container(width: 62, height: 62, decoration: const BoxDecoration(color: AppColors.bluePale, shape: BoxShape.circle), child: const Icon(Icons.sticky_note_2_rounded, color: AppColors.blue, size: 28)),
              const SizedBox(height: 13),
              Text(_query.isEmpty ? context.dp('Your notes will appear here.') : context.dp('No notes match your search.'), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(context.dp('Capture ideas, reminders and things worth remembering.'), textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4)),
              const SizedBox(height: 17),
              OutlinedButton.icon(onPressed: () => showRecordEditor(context, widget.controller, type: RecordType.note), icon: const Icon(Icons.add_rounded, size: 17), label: Text(context.dp('Create your first note'))),
            ]),
          )
        else
          ...notes.map((note) => _NoteCard(
                note: note,
                onTap: () => showRecordEditor(context, widget.controller, type: RecordType.note, record: note),
                onDelete: () => _confirmDelete(note),
              )),
      ],
    );
  }

  Future<void> _confirmDelete(AppRecord note) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.dp('Delete note?')),
        content: Text(context.dp('This note will be removed from this device.')),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.dp('Cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.dp('Delete')))],
      ),
    );
    if (remove == true) await widget.controller.deleteRecord(note);
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap, required this.onDelete});
  final AppRecord note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 11),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(19)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 39, height: 39, decoration: BoxDecoration(color: AppColors.yellowPale, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.sticky_note_2_rounded, color: Color(0xFFD9A739), size: 19)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 5),
                Text(note.body.isEmpty ? context.dp('No additional text') : note.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4)),
                const SizedBox(height: 9),
                Text('Updated ${DateFormat('d MMM, h:mm a').format(note.updatedAt)}', style: const TextStyle(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ])),
              PopupMenuButton<String>(
                onSelected: (value) { if (value == 'delete') onDelete(); if (value == 'edit') onTap(); },
                itemBuilder: (context) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
                icon: const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
              ),
            ]),
          ),
        ),
      );
}

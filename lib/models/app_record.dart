import 'dart:convert';

class AppRecord {
  const AppRecord({
    required this.id,
    required this.type,
    required this.date,
    required this.title,
    this.body = '',
    this.startAt,
    this.endAt,
    this.done = false,
    this.meta = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final DateTime date;
  final String title;
  final String body;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool done;
  final Map<String, dynamic> meta;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppRecord copyWith({
    String? type,
    DateTime? date,
    String? title,
    String? body,
    DateTime? startAt,
    DateTime? endAt,
    bool? done,
    Map<String, dynamic>? meta,
    DateTime? updatedAt,
    bool clearStartAt = false,
    bool clearEndAt = false,
  }) {
    return AppRecord(
      id: id,
      type: type ?? this.type,
      date: date ?? this.date,
      title: title ?? this.title,
      body: body ?? this.body,
      startAt: clearStartAt ? null : (startAt ?? this.startAt),
      endAt: clearEndAt ? null : (endAt ?? this.endAt),
      done: done ?? this.done,
      meta: meta ?? Map<String, dynamic>.from(this.meta),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type,
        'date': date.toIso8601String(),
        'title': title,
        'body': body,
        'start_at': startAt?.toIso8601String(),
        'end_at': endAt?.toIso8601String(),
        'done': done ? 1 : 0,
        'meta': jsonEncode(meta),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AppRecord.fromMap(Map<String, Object?> map) {
    final metaJson = map['meta'] as String? ?? '{}';
    return AppRecord(
      id: map['id'] as String,
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      startAt: map['start_at'] == null
          ? null
          : DateTime.tryParse(map['start_at'] as String),
      endAt: map['end_at'] == null
          ? null
          : DateTime.tryParse(map['end_at'] as String),
      done: (map['done'] as int? ?? 0) == 1,
      meta: Map<String, dynamic>.from(jsonDecode(metaJson) as Map),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'date': date.toIso8601String(),
        'title': title,
        'body': body,
        'startAt': startAt?.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
        'done': done,
        'meta': meta,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AppRecord.fromJson(Map<String, dynamic> json) => AppRecord(
        id: json['id'] as String,
        type: json['type'] as String,
        date: DateTime.parse(json['date'] as String),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        startAt: json['startAt'] == null
            ? null
            : DateTime.parse(json['startAt'] as String),
        endAt: json['endAt'] == null
            ? null
            : DateTime.parse(json['endAt'] as String),
        done: json['done'] as bool? ?? false,
        meta: Map<String, dynamic>.from(json['meta'] as Map? ?? {}),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

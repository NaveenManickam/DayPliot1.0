import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
String monthHeading(DateTime date) => DateFormat('MMMM yyyy').format(date);
String shortDate(DateTime date) => DateFormat('EEE, d MMM').format(date);
String timeLabel(DateTime date) => DateFormat('h:mm a').format(date);

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

List<DateTime> monthGrid(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final start = first.subtract(Duration(days: (first.weekday + 6) % 7));
  return List.generate(42, (i) => start.add(Duration(days: i)));
}

List<DateTime> weekDays(DateTime date) {
  final start = dateOnly(date).subtract(Duration(days: (date.weekday + 6) % 7));
  return List.generate(7, (i) => start.add(Duration(days: i)));
}

bool sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Color dateAccent(DateTime date) => date.weekday == DateTime.sunday
    ? const Color(0xFFE85E7A)
    : const Color(0xFF5968F2);

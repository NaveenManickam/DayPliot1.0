import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const appName = 'DayPilot';
  static const applicationId = 'com.naveenmanickam.daypilot';
  static const databaseName = 'daypilot.db';
  static const databaseVersion = 1;
  static const defaultWaterTargetMl = 2000;
  static const quoteCount = 18;
}

abstract final class AppColors {
  static const canvas = Color(0xFFF7F8FC);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF20243A);
  static const muted = Color(0xFF8B90A5);
  static const line = Color(0xFFE9EAF2);
  static const blue = Color(0xFF5968F2);
  static const blueDeep = Color(0xFF4454DF);
  static const bluePale = Color(0xFFECEEFF);
  static const coral = Color(0xFFE85E7A);
  static const coralPale = Color(0xFFFFE8ED);
  static const mint = Color(0xFF37B99A);
  static const mintPale = Color(0xFFE3F8F1);
  static const yellow = Color(0xFFF2C45E);
  static const yellowPale = Color(0xFFFFF5D9);
  static const lilac = Color(0xFFE8E7FA);
  static const darkCanvas = Color(0xFF171927);
  static const darkCard = Color(0xFF22263A);
  static const darkInk = Color(0xFFF3F4FA);
  static const darkMuted = Color(0xFF9BA1B8);
}

abstract final class RecordType {
  static const task = 'task';
  static const habit = 'habit';
  static const habitCheck = 'habit_check';
  static const event = 'event';
  static const note = 'note';
  static const dateNote = 'date_note';
  static const journal = 'journal';
  static const water = 'water';
  static const exercise = 'exercise';
  static const sleep = 'sleep';
  static const mood = 'mood';
}

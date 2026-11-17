import 'package:flutter/material.dart';

import '../core/app_constants.dart';

class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
          primary: AppColors.blue,
          secondary: AppColors.coral,
          surface: AppColors.white,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.12),
          headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
          titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
          bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
          bodyMedium: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.35),
          labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.canvas,
          foregroundColor: AppColors.ink,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.canvas,
          hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
          labelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.blue, width: 1.4)),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        dividerColor: AppColors.line,
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkCanvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.dark,
          primary: const Color(0xFF8791FF),
          secondary: const Color(0xFFFF8DA1),
          surface: AppColors.darkCard,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D3146),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      );
}

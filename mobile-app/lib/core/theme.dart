import 'package:flutter/material.dart';

ThemeData buildTheme() {
  const seed = Color(0xFF0F766E);
  final theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(),
    ),
  );
  return _applySharedDatePickerTheme(theme);
}

ThemeData buildDarkTheme() {
  const seed = Color(0xFF14B8A6);
  final theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0B1220),
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(),
    ),
  );
  return _applySharedDatePickerTheme(theme);
}

ThemeData _applySharedDatePickerTheme(ThemeData theme) {
  final color = theme.colorScheme;
  return theme.copyWith(
    datePickerTheme: DatePickerThemeData(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      headerBackgroundColor: color.primaryContainer,
      headerForegroundColor: color.onPrimaryContainer,
      todayForegroundColor: WidgetStatePropertyAll(color.primary),
      todayBackgroundColor:
          WidgetStatePropertyAll(color.primary.withValues(alpha: 0.12)),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return color.onPrimary;
        return color.onSurface;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return color.primary;
        return null;
      }),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return color.onPrimary;
        return color.onSurface;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return color.primary;
        return null;
      }),
      rangeSelectionBackgroundColor: color.primary.withValues(alpha: 0.16),
      rangeSelectionOverlayColor:
          WidgetStatePropertyAll(color.primary.withValues(alpha: 0.10)),
    ),
  );
}

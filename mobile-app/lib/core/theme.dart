import 'package:flutter/material.dart';

ThemeData buildTheme() {
  return _buildAppTheme();
}

ThemeData buildDarkTheme() {
  return _buildAppTheme();
}

ThemeData _buildAppTheme() {
  const seed = Color(0xFF14B8A6);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
    surface: const Color(0xFF0F172A),
    primary: const Color(0xFF19B7A5),
    secondary: const Color(0xFF38BDF8),
  );

  final theme = ThemeData(
    colorScheme: scheme,
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF08111F),
    canvasColor: const Color(0xFF08111F),
    dividerColor: scheme.outlineVariant,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: const Color(0xFF0A1325),
      foregroundColor: scheme.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF0F172A),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF0A1325),
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF111827),
      contentTextStyle: TextStyle(color: scheme.onSurface),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      circularTrackColor: scheme.primary.withValues(alpha: 0.16),
      linearTrackColor: scheme.primary.withValues(alpha: 0.12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF111C31),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      hintStyle:
          TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.72)),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: 0.30),
      selectionHandleColor: scheme.primary,
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

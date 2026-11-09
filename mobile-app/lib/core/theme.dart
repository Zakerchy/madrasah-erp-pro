import 'package:flutter/material.dart';

/// Project brand colors — deep green + gold, the same tones as the official
/// seal. Single source of truth so every screen (not just the public
/// landing page) stays visually consistent without re-deciding colors.
class AppBrand {
  AppBrand._();

  static const green = Color(0xFF0E4D3A);
  static const greenDark = Color(0xFF083024);
  static const greenLight = Color(0xFF1E8A68); // brighter tint, for contrast on dark backgrounds
  static const gold = Color(0xFFC9A227);
  static const goldLight = Color(0xFFE6C861);
  static const cream = Color(0xFFFBF8F0);
}

ThemeData buildTheme() => _buildAppTheme(Brightness.light);

ThemeData buildDarkTheme() => _buildAppTheme(Brightness.dark);

ThemeData _buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final scheme = ColorScheme.fromSeed(
    seedColor: AppBrand.green,
    brightness: brightness,
    primary: isDark ? AppBrand.greenLight : AppBrand.green,
    secondary: AppBrand.gold,
    surface: isDark ? const Color(0xFF0C2019) : Colors.white,
  );

  final scaffoldBg = isDark ? const Color(0xFF071711) : AppBrand.cream;
  final cardBg = isDark ? const Color(0xFF0C2019) : Colors.white;
  final appBarBg = isDark ? const Color(0xFF0A1C15) : Colors.white;
  final inputFill = isDark ? const Color(0xFF0F2A20) : const Color(0xFFF4F0E4);
  final borderColor = isDark ? AppBrand.gold.withValues(alpha: 0.28) : AppBrand.gold.withValues(alpha: 0.4);

  final theme = ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: scaffoldBg,
    canvasColor: scaffoldBg,
    dividerColor: scheme.outlineVariant,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: appBarBg,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: appBarBg,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? const Color(0xFF123023) : AppBrand.greenDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      circularTrackColor: scheme.primary.withValues(alpha: 0.16),
      linearTrackColor: scheme.primary.withValues(alpha: 0.12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: isDark ? AppBrand.greenDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppBrand.gold.withValues(alpha: 0.7)),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: isDark ? AppBrand.greenDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppBrand.gold.withValues(alpha: 0.7)),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
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

import 'package:flutter/material.dart';

Future<DateTime?> showThemedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
}) {
  final theme = Theme.of(context);
  final color = theme.colorScheme;

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    initialDatePickerMode: initialDatePickerMode,
    builder: (ctx, child) {
      return Theme(
        data: theme.copyWith(
          datePickerTheme: DatePickerThemeData(
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
            rangeSelectionBackgroundColor:
                color.primary.withValues(alpha: 0.16),
            rangeSelectionOverlayColor:
                WidgetStatePropertyAll(color.primary.withValues(alpha: 0.10)),
          ),
        ),
        child: child!,
      );
    },
  );
}

Future<DateTimeRange?> showThemedDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  required DateTimeRange initialDateRange,
}) {
  final theme = Theme.of(context);
  final color = theme.colorScheme;
  return showDateRangePicker(
    context: context,
    firstDate: firstDate,
    lastDate: lastDate,
    initialDateRange: initialDateRange,
    builder: (ctx, child) {
      return Theme(
        data: theme.copyWith(
          datePickerTheme: DatePickerThemeData(
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            headerBackgroundColor: color.primaryContainer,
            headerForegroundColor: color.onPrimaryContainer,
            rangeSelectionBackgroundColor:
                color.primary.withValues(alpha: 0.16),
            rangeSelectionOverlayColor:
                WidgetStatePropertyAll(color.primary.withValues(alpha: 0.10)),
          ),
        ),
        child: child!,
      );
    },
  );
}

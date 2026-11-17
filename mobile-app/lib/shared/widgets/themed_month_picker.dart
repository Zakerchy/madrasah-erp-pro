import 'package:flutter/material.dart';

import '../../core/app_lang.dart';

/// Opens a clean themed month picker dialog and returns a `YYYY-MM` string
/// (or null if cancelled).
Future<String?> showThemedMonthPicker({
  required BuildContext context,
  String? initialMonth,
  int minYear = 2020,
  int maxYear = 2035,
}) async {
  final now = DateTime.now();
  var selectedYear = now.year;
  var selectedMonth = now.month;

  if (initialMonth != null &&
      RegExp(r'^\d{4}-\d{2}$').hasMatch(initialMonth.trim())) {
    final parts = initialMonth.trim().split('-');
    selectedYear = int.tryParse(parts[0]) ?? now.year;
    selectedMonth = (int.tryParse(parts[1]) ?? now.month).clamp(1, 12);
  }

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      var year = selectedYear.clamp(minYear, maxYear);
      var month = selectedMonth;

      return StatefulBuilder(
        builder: (ctx, setState) {
          final scheme = Theme.of(ctx).colorScheme;
          const monthNamesBn = [
            'জানু',
            'ফেব্রু',
            'মার্চ',
            'এপ্রিল',
            'মে',
            'জুন',
            'জুলাই',
            'আগস্ট',
            'সেপ্টে',
            'অক্টো',
            'নভে',
            'ডিসে',
          ];
          const monthNamesEn = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLang.t('মাস নির্বাচন করুন', 'Select Month')),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: AppLang.t('আগের বছর', 'Previous year'),
                      onPressed:
                          year > minYear ? () => setState(() => year--) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '$year',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      tooltip: AppLang.t('পরের বছর', 'Next year'),
                      onPressed:
                          year < maxYear ? () => setState(() => year++) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            content: SizedBox(
              width: 300,
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.1,
                ),
                itemBuilder: (_, idx) {
                  final m = idx + 1;
                  final isSelected = m == month;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => month = m),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? scheme.primary
                            : scheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        AppLang.t(monthNamesBn[idx], monthNamesEn[idx]),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLang.t('বাতিল', 'Cancel')),
              ),
              FilledButton(
                onPressed: () {
                  final formatted =
                      '$year-${month.toString().padLeft(2, '0')}';
                  Navigator.pop(ctx, formatted);
                },
                child: Text(AppLang.t('নির্বাচন', 'Select')),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Drop-in month selector field showing `YYYY-MM` and opening [showThemedMonthPicker].
class MonthPickerField extends StatelessWidget {
  final String value;
  final String? label;
  final ValueChanged<String> onChanged;

  const MonthPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showThemedMonthPicker(
          context: context,
          initialMonth: value,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label ?? AppLang.t('মাস (YYYY-MM)', 'Month (YYYY-MM)'),
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value.isEmpty ? AppLang.t('নির্বাচন করুন', 'Select') : value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

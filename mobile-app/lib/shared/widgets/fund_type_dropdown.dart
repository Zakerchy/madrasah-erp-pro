import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../constants/fund_types.dart';

/// Fund-type dropdown — সব screen-এ একই widget ব্যবহার হবে।
/// [adminMode]: true হলে সব fund দেখাবে; false হলে শুধু donorVisible।
class FundTypeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool adminMode;
  final InputDecoration? decoration;

  const FundTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.adminMode = true,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final funds = adminMode ? FundTypes.all : FundTypes.donorVisible;

    // যদি current value fund list-এ না থাকে (legacy key) — canonical key-তে normalize
    final canonical = FundTypes.canonical(value);
    final validValue = funds.any((f) => f.key == canonical) ? canonical : funds.first.key;

    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (_, isEn, __) => DropdownButtonFormField<String>(
        initialValue: validValue,
        items: funds
            .map((f) => DropdownMenuItem(
                  value: f.key,
                  child: Text(isEn ? f.labelEn : f.labelBn),
                ))
            .toList(),
        onChanged: (v) => onChanged(v ?? funds.first.key),
        decoration: decoration ??
            InputDecoration(labelText: AppLang.t('ফান্ড ধরন', 'Fund Type')),
      ),
    );
  }
}

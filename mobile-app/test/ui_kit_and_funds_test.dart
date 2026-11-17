import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madrasah_erp_pro/shared/constants/fund_types.dart';
import 'package:madrasah_erp_pro/shared/widgets/empty_state_view.dart';
import 'package:madrasah_erp_pro/shared/widgets/primary_async_button.dart';
import 'package:madrasah_erp_pro/shared/widgets/status_badge.dart';
import 'package:madrasah_erp_pro/shared/widgets/themed_month_picker.dart';

void main() {
  test('FundTypes.byKey maps legacy and canonical keys', () {
    expect(FundTypes.byKey('CONSTRUCTION')?.key, 'SADAQAH');
    expect(FundTypes.byKey('JAKAT')?.key, 'ZAKAT');
    expect(FundTypes.byKey('SCHOLARSHIP')?.key, 'TALEBE_ELM');
    expect(FundTypes.byKey('yatim')?.key, 'YATIM');
    expect(FundTypes.byKey('UNKNOWN_KEY'), isNull);
  });

  testWidgets('StatusBadge renders localized status label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: 'CONFIRMED'),
        ),
      ),
    );
    expect(find.byType(StatusBadge), findsOneWidget);
  });

  testWidgets('EmptyStateView renders title and triggers action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            icon: Icons.inbox,
            title: 'Empty',
            subtitle: 'Nothing here',
            actionLabel: 'Add',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Empty'), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    await tester.tap(find.text('Add'));
    expect(tapped, isTrue);
  });

  testWidgets('MonthPickerField shows current value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthPickerField(
            value: '2026-11',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('2026-11'), findsOneWidget);
  });

  testWidgets('PrimaryAsyncButton prevents double-tap while busy', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryAsyncButton(
            label: 'Save',
            onPressed: () async {
              calls++;
              await Future<void>.delayed(const Duration(milliseconds: 50));
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
}

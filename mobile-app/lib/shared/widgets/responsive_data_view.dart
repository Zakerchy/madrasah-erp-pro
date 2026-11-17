import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import 'empty_state_view.dart';

/// Renders a searchable DataTable on wide screens (>= 900px) and compact
/// custom cards on mobile screens (< 900px).
class ResponsiveDataView<T> extends StatefulWidget {
  final List<T> items;
  final List<DataColumn> columns;
  final List<DataCell> Function(T item) rowBuilder;
  final Widget Function(BuildContext context, T item) mobileCardBuilder;
  final bool Function(T item, String query)? searchFilter;
  final String? searchHint;
  final String? emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final double desktopBreakpoint;

  const ResponsiveDataView({
    super.key,
    required this.items,
    required this.columns,
    required this.rowBuilder,
    required this.mobileCardBuilder,
    this.searchFilter,
    this.searchHint,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.desktopBreakpoint = 900,
  });

  @override
  State<ResponsiveDataView<T>> createState() => _ResponsiveDataViewState<T>();
}

class _ResponsiveDataViewState<T> extends State<ResponsiveDataView<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty || widget.searchFilter == null
        ? widget.items
        : widget.items
            .where((item) => widget.searchFilter!(item, _query.trim().toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.searchFilter != null) ...[
          TextField(
            onChanged: (val) => setState(() => _query = val),
            decoration: InputDecoration(
              hintText: widget.searchHint ??
                  AppLang.t('খুঁজুন...', 'Search...'),
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (filtered.isEmpty)
          EmptyStateView(
            icon: widget.emptyIcon,
            title: widget.emptyTitle ??
                AppLang.t('কোনো তথ্য পাওয়া যায়নি', 'No records found'),
            subtitle: widget.emptySubtitle,
            actionLabel: widget.emptyActionLabel,
            onAction: widget.onEmptyAction,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= widget.desktopBreakpoint) {
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.06),
                        ),
                        columns: widget.columns,
                        rows: filtered
                            .map((item) => DataRow(cells: widget.rowBuilder(item)))
                            .toList(),
                      ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) =>
                    widget.mobileCardBuilder(ctx, filtered[idx]),
              );
            },
          ),
      ],
    );
  }
}

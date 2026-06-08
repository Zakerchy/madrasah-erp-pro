import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shared/services/api_service.dart';

class FundDetailPage extends StatefulWidget {
  final String fundKey;
  final String fundName;

  const FundDetailPage({
    super.key,
    required this.fundKey,
    required this.fundName,
  });

  @override
  State<FundDetailPage> createState() => _FundDetailPageState();
}

class _FundDetailPageState extends State<FundDetailPage> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _txns = [];
  String _selectedMonth = '';

  double _totalIn = 0;
  double _totalOut = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final parts = _selectedMonth.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final from = '$_selectedMonth-01';
      final to =
          '$_selectedMonth-${DateUtils.getDaysInMonth(year, month).toString().padLeft(2, '0')}';

      final res = await _api.get('listTransactions', query: {
        'fundType': widget.fundKey,
        'from': from,
        'to': to,
      }, forceRefresh: forceRefresh);

      if (res['ok'] == true) {
        final data = (res['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        data.sort((a, b) => (b['txn_date'] ?? '').compareTo(a['txn_date'] ?? ''));
        _txns = data;
        _totalIn = data
            .where((t) => t['direction'] == 'IN')
            .fold(0.0, (sum, t) => sum + (double.tryParse(t['amount'].toString()) ?? 0));
        _totalOut = data
            .where((t) => t['direction'] == 'OUT')
            .fold(0.0, (sum, t) => sum + (double.tryParse(t['amount'].toString()) ?? 0));
      } else {
        _error = (res['message'] ?? 'তথ্য লোড ব্যর্থ').toString();
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  String _fmt(double n) =>
      '৳${NumberFormat('#,##0.##', 'en_US').format(n)}';

  String _monthLabel(String key) {
    try {
      final d = DateFormat('yyyy-MM').parse(key);
      return DateFormat('MMMM yyyy').format(d);
    } catch (_) {
      return key;
    }
  }

  Future<void> _pickMonth() async {
    // Build last 24 months options
    final months = <String>[];
    final now = DateTime.now();
    for (int i = 0; i < 24; i++) {
      var m = now.month - i;
      var y = now.year;
      while (m <= 0) {
        m += 12;
        y--;
      }
      months.add('$y-${m.toString().padLeft(2, '0')}');
    }

    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('মাস নির্বাচন করুন',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...months.map((m) => ListTile(
                title: Text(_monthLabel(m)),
                selected: m == _selectedMonth,
                selectedColor: Theme.of(ctx).colorScheme.primary,
                onTap: () => Navigator.pop(ctx, m),
              )),
        ],
      ),
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() => _selectedMonth = picked);
      await _load(forceRefresh: true);
    }
  }

  Color _fundColor() {
    switch (widget.fundKey) {
      case 'CONSTRUCTION':
        return const Color(0xFF1D4ED8);
      case 'JAKAT':
        return const Color(0xFF15803D);
      case 'SCHOLARSHIP':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFFB45309);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _fundColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(widget.fundName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _pickMonth,
            icon: const Icon(Icons.calendar_month, color: Colors.white70, size: 18),
            label: Text(
              _monthLabel(_selectedMonth),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: () => _load(forceRefresh: true),
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month summary banner
          Container(
            color: color.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: '↑ মোট আয়',
                    value: _fmt(_totalIn),
                    color: Colors.green.shade700,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: '↓ মোট ব্যয়',
                    value: _fmt(_totalOut),
                    color: Colors.red.shade700,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: '= ব্যালেন্স',
                    value: _fmt(_totalIn - _totalOut),
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton(
                                onPressed: () => _load(forceRefresh: true),
                                child: const Text('পুনরায় চেষ্টা করুন')),
                          ],
                        ),
                      )
                    : _txns.isEmpty
                        ? Center(
                            child: Text(
                              '${_monthLabel(_selectedMonth)}-এ কোনো লেনদেন নেই',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _txns.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) => _TxnTile(txn: _txns[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}

class _TxnTile extends StatelessWidget {
  final Map<String, dynamic> txn;

  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isIn = txn['direction'] == 'IN';
    final amount = double.tryParse(txn['amount'].toString()) ?? 0;
    final date = txn['txn_date']?.toString() ?? '';
    final source = txn['source_or_vendor']?.toString() ?? '';
    final category = txn['category']?.toString() ?? '';
    final notes = txn['notes']?.toString() ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isIn
            ? Colors.green.shade50
            : Colors.red.shade50,
        child: Icon(
          isIn ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: isIn ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
      title: Text(
        source.isNotEmpty ? source : category,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          if (notes.isNotEmpty)
            Text(notes,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: Text(
        '${isIn ? '+' : '−'}৳${NumberFormat('#,##0', 'en_US').format(amount.toInt())}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isIn ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }
}

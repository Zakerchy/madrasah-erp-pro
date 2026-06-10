import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/app_permissions.dart';
import '../../shared/services/access_control_service.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';
import '../../shared/widgets/themed_date_picker.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _date = TextEditingController();
  final _amount = TextEditingController();
  final _vendor = TextEditingController();
  final _head = TextEditingController();
  final _note = TextEditingController();

  String _fundType = 'CONSTRUCTION';
  bool _saving = false;
  bool _loadingList = true;
  List<Map<String, dynamic>> _rows = [];

  bool get _canWrite => SessionService.can(AppPermissions.expensesWrite);

  @override
  void initState() {
    super.initState();
    _date.text = DateTime.now().toIso8601String().split('T').first;
    _loadRows();
  }

  Future<void> _loadRows({bool forceRefresh = false}) async {
    setState(() => _loadingList = true);
    try {
      final res = await _api.get(
        'listTransactions',
        query: {'direction': 'OUT'},
        forceRefresh: forceRefresh,
      );
      if (res['ok'] == true) {
        final data = (res['data'] as List<dynamic>? ?? []);
        _rows = data
            .take(30)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingList = false);
  }

  DateTime? _parseIsoDate(String value) {
    final trimmed = value.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) return null;
    final dt = DateTime.tryParse(trimmed);
    if (dt == null) return null;
    final normalized =
        '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    return normalized == trimmed ? dt : null;
  }

  Future<void> _pickDate() async {
    final initial = _parseIsoDate(_date.text) ?? DateTime.now();
    final picked = await showThemedDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    _date.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canWrite) {
      AccessControlService.showDeniedSnack(
        context,
        permission: AppPermissions.expensesWrite,
        routeName: '/expenses',
      );
      return;
    }

    final enteredAmount = double.tryParse(_amount.text.trim()) ?? 0;
    final enteredHead = _head.text.trim().toLowerCase();
    final now = DateTime.now();
    final hasDuplicate = _rows.any((r) {
      final rowAmt = double.tryParse(r['amount'].toString()) ?? 0;
      final rowHead = (r['category'] ?? '').toString().toLowerCase();
      if (rowAmt != enteredAmount || rowHead != enteredHead) return false;
      final rowDate = _parseIsoDate(r['txn_date']?.toString() ?? '');
      return rowDate != null && now.difference(rowDate).inHours.abs() < 24;
    });
    if (hasDuplicate) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLang.t('সম্ভাব্য ডুপ্লিকেট', 'Possible Duplicate')),
          content: Text(AppLang.t(
            'একই পরিমাণ ও খরচের খাতে সম্প্রতি লেনদেন আছে। তবুও সংরক্ষণ করবেন?',
            'A recent transaction with same amount and expense head exists. Save anyway?',
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLang.t('বাতিল', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLang.t('হ্যাঁ, সংরক্ষণ', 'Yes, Save')),
            ),
          ],
        ),
      );
      if (!mounted || proceed != true) return;
    }
    setState(() => _saving = true);
    try {
      final res = await _api.post('createTransaction', {
        'user_role': SessionService.role,
        'payload': {
          'txn_date': _date.text.trim(),
          'direction': 'OUT',
          'fund_type': _fundType,
          'amount': double.tryParse(_amount.text.trim()) ?? 0,
          'source_or_vendor':
              _vendor.text.trim().isEmpty ? 'Expense' : _vendor.text.trim(),
          'category': _head.text.trim(),
          'notes': _note.text.trim(),
          'created_by': SessionService.userId,
        }
      });

      if (!mounted) return;
      if (res['ok'] == true) {
        _amount.clear();
        _vendor.clear();
        _head.clear();
        _note.clear();
        await _loadRows();
        if (!mounted) return;
        final msg = res['queued'] == true
            ? AppLang.t('অফলাইনে সংরক্ষিত। সংযোগে এলে পাঠানো হবে।',
                'Offline saved. Will sync automatically.')
            : AppLang.t('খরচ সফলভাবে সংরক্ষিত', 'Expense saved successfully');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${res['message'] ?? res['error']}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLang.t('ত্রুটি', 'Error')}: $e')));
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, isEn, _) => BaseScaffold(
        title: AppLang.t('খরচ', 'Expenses'),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _date,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText:
                          AppLang.t('তারিখ (YYYY-MM-DD)', 'Date (YYYY-MM-DD)'),
                      suffixIcon: IconButton(
                        tooltip: AppLang.t('তারিখ নির্বাচন', 'Select date'),
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ),
                    onTap: _pickDate,
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) {
                        return AppLang.t('তারিখ দিন', 'Date required');
                      }
                      final parsed = _parseIsoDate(value);
                      if (parsed == null) {
                        return AppLang.t('বৈধ তারিখ দিন YYYY-MM-DD',
                            'Use valid date YYYY-MM-DD');
                      }
                      if (parsed.isAfter(DateTime.now())) {
                        return AppLang.t('ভবিষ্যৎ তারিখ দেওয়া যাবে না',
                            'Future date not allowed');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _fundType,
                    items: [
                      DropdownMenuItem(
                          value: 'CONSTRUCTION',
                          child: Text(AppLang.t('নির্মাণ', 'Construction'))),
                      DropdownMenuItem(
                          value: 'JAKAT',
                          child: Text(AppLang.t('যাকাত', 'Jakat'))),
                      DropdownMenuItem(
                          value: 'SCHOLARSHIP',
                          child: Text(AppLang.t('বৃত্তি', 'Scholarship'))),
                      DropdownMenuItem(
                          value: 'GENERAL',
                          child: Text(AppLang.t('সাধারণ', 'General'))),
                    ],
                    onChanged: (v) =>
                        setState(() => _fundType = v ?? 'CONSTRUCTION'),
                    decoration: InputDecoration(
                        labelText: AppLang.t('ফান্ড ধরন', 'Fund Type')),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: AppLang.t('পরিমাণ', 'Amount')),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim()) ?? 0;
                      return n <= 0
                          ? AppLang.t(
                              'পরিমাণ ০ এর বেশি হতে হবে', 'Amount must be > 0')
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _head,
                    decoration: InputDecoration(
                        labelText: AppLang.t('খরচের খাত', 'Expense Head')),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppLang.t('খরচের খাত দিন', 'Expense head required')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vendor,
                    decoration: InputDecoration(
                        labelText: AppLang.t('বিক্রেতা/প্রাপক (ঐচ্ছিক)',
                            'Vendor/Receiver (optional)')),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _note,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                        labelText: AppLang.t('মন্তব্য', 'Notes')),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_saving
                          ? AppLang.t('সংরক্ষণ হচ্ছে...', 'Saving...')
                          : AppLang.t('খরচ সংরক্ষণ', 'Save Expense')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(AppLang.t('সাম্প্রতিক খরচ', 'Recent Expenses'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: () => _loadRows(forceRefresh: true),
                    icon: const Icon(Icons.refresh)),
              ],
            ),
            if (_loadingList)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ..._rows.map((r) => Card(
                    child: ListTile(
                      title: Text(
                          '${r['category'] ?? AppLang.t('খরচ', 'Expense')} • ৳${r['amount'] ?? 0}'),
                      subtitle: Text(
                          '${r['fund_type'] ?? ''} • ${r['txn_date'] ?? ''} • ${r['source_or_vendor'] ?? ''}'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

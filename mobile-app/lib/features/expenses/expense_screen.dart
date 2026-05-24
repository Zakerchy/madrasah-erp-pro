import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

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

  @override
  void initState() {
    super.initState();
    _date.text = DateTime.now().toIso8601String().split('T').first;
    _loadRows();
  }

  Future<void> _loadRows() async {
    setState(() => _loadingList = true);
    try {
      final res = await _api.get('listTransactions', query: {'direction': 'OUT'});
      if (res['ok'] == true) {
        final data = (res['data'] as List<dynamic>? ?? []);
        _rows = data.take(30).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingList = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final res = await _api.post('createTransaction', {
        'user_role': SessionService.role,
        'payload': {
          'txn_date': _date.text.trim(),
          'direction': 'OUT',
          'fund_type': _fundType,
          'amount': double.tryParse(_amount.text.trim()) ?? 0,
          'source_or_vendor': _vendor.text.trim().isEmpty ? 'Expense' : _vendor.text.trim(),
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
        final msg = res['queued'] == true
            ? AppLang.t('অফলাইনে সংরক্ষিত। সংযোগে এলে পাঠানো হবে।', 'Offline saved. Will sync automatically.')
            : AppLang.t('খরচ সফলভাবে সংরক্ষিত', 'Expense saved successfully');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${res['message'] ?? res['error']}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLang.t('ত্রুটি', 'Error')}: $e')));
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
                    decoration: InputDecoration(labelText: AppLang.t('তারিখ (YYYY-MM-DD)', 'Date (YYYY-MM-DD)')),
                    validator: (v) => (v == null || v.trim().isEmpty) ? AppLang.t('তারিখ দিন', 'Date required') : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _fundType,
                    items: [
                      DropdownMenuItem(value: 'CONSTRUCTION', child: Text(AppLang.t('নির্মাণ', 'Construction'))),
                      DropdownMenuItem(value: 'JAKAT', child: Text(AppLang.t('যাকাত', 'Jakat'))),
                      DropdownMenuItem(value: 'SCHOLARSHIP', child: Text(AppLang.t('বৃত্তি', 'Scholarship'))),
                      DropdownMenuItem(value: 'GENERAL', child: Text(AppLang.t('সাধারণ', 'General'))),
                    ],
                    onChanged: (v) => setState(() => _fundType = v ?? 'CONSTRUCTION'),
                    decoration: InputDecoration(labelText: AppLang.t('ফান্ড ধরন', 'Fund Type')),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: AppLang.t('পরিমাণ', 'Amount')),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').trim()) ?? 0;
                      return n <= 0 ? AppLang.t('পরিমাণ ০ এর বেশি হতে হবে', 'Amount must be > 0') : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _head,
                    decoration: InputDecoration(labelText: AppLang.t('খরচের খাত', 'Expense Head')),
                    validator: (v) => (v == null || v.trim().isEmpty) ? AppLang.t('খরচের খাত দিন', 'Expense head required') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vendor,
                    decoration: InputDecoration(labelText: AppLang.t('বিক্রেতা/প্রাপক (ঐচ্ছিক)', 'Vendor/Receiver (optional)')),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _note,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: AppLang.t('মন্তব্য', 'Notes')),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_saving ? AppLang.t('সংরক্ষণ হচ্ছে...', 'Saving...') : AppLang.t('খরচ সংরক্ষণ', 'Save Expense')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(AppLang.t('সাম্প্রতিক খরচ', 'Recent Expenses'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: _loadRows, icon: const Icon(Icons.refresh)),
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
                      title: Text('${r['category'] ?? AppLang.t('খরচ', 'Expense')} • ৳${r['amount'] ?? 0}'),
                      subtitle: Text('${r['fund_type'] ?? ''} • ${r['txn_date'] ?? ''} • ${r['source_or_vendor'] ?? ''}'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

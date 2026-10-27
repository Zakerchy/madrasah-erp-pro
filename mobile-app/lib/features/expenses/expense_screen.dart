import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/app_permissions.dart';
import '../../shared/services/access_control_service.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/constants/fund_types.dart';
import '../../shared/widgets/base_scaffold.dart';
import '../../shared/widgets/fund_type_dropdown.dart';
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

  String _fundType = 'SADAQAH';
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

  Future<void> _openAutoDeductSheet(Map<String, dynamic> expense) async {
    final expenseId = expense['id'] as String?;
    if (expenseId == null) return;
    final fundType = (expense['fund_type'] as String?) ?? '';
    final amountCtrl = TextEditingController(text: '${expense['amount'] ?? ''}');

    bool loading = false;
    bool previewed = false;
    List<Map<String, dynamic>> allocations = [];
    double covered = 0;
    double shortfall = 0;
    String? error;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> preview() async {
            setSheet(() { loading = true; error = null; });
            final res = await _api.post('autoDeductPreview', {
              'user_role': SessionService.role,
              'payload': {
                'fund_type': fundType,
                'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
              },
            });
            if (res['ok'] == true) {
              allocations = (res['allocations'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
              covered = (res['covered'] as num? ?? 0).toDouble();
              shortfall = (res['shortfall'] as num? ?? 0).toDouble();
              previewed = true;
            } else {
              error = res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error');
            }
            setSheet(() => loading = false);
          }

          Future<void> commit() async {
            setSheet(() => loading = true);
            final res = await _api.post('autoDeductCommit', {
              'user_role': SessionService.role,
              'payload': {
                'expense_id': expenseId,
                'fund_type': fundType,
                'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
              },
            });
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(res['ok'] == true
                    ? AppLang.t('বণ্টন সম্পন্ন হয়েছে', 'Split completed')
                    : (res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
              ));
              if (res['ok'] == true && (res['shortfall'] as num? ?? 0) > 0) {
                _openNotifyDonorsDialog(fundType, (res['shortfall'] as num).toDouble());
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLang.t('স্বয়ংক্রিয় বণ্টন — একাধিক দানকারীর মধ্যে ভাগ করুন', 'Auto-split across donor balances'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: AppLang.t('মোট পরিমাণ (৳)', 'Total amount (৳)')),
                  onChanged: (_) => setSheet(() => previewed = false),
                ),
                const SizedBox(height: 12),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (previewed) ...[
                  Text(AppLang.t('যেভাবে কাটা হবে (পুরনো দান আগে):', 'Allocation (oldest donation first):'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ...allocations.map((a) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• ${a['donor_name_bn'] ?? ''} — ৳${a['amount']}'),
                      )),
                  const SizedBox(height: 8),
                  Text(AppLang.t('মোট কভার হয়েছে: ৳$covered', 'Total covered: ৳$covered'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (shortfall > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        AppLang.t('ঘাটতি: ৳$shortfall (এই ফান্ডে আর কোনো দানকারীর ব্যালেন্স নেই)',
                            'Shortfall: ৳$shortfall (no more donor balance in this fund)'),
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: previewed
                      ? FilledButton(
                          onPressed: loading || allocations.isEmpty ? null : commit,
                          child: loading
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(AppLang.t('নিশ্চিত করে বণ্টন করুন', 'Confirm & Split')),
                        )
                      : FilledButton(
                          onPressed: loading ? null : preview,
                          child: loading
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(AppLang.t('প্রিভিউ দেখুন', 'Preview Split')),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openNotifyDonorsDialog(String fundType, double shortfall) async {
    if (!mounted) return;
    final ftDef = FundTypes.byKey(fundType);
    final ft = AppLang.isEnglish.value ? (ftDef?.labelEn ?? fundType) : (ftDef?.labelBn ?? fundType);
    final messageCtrl = TextEditingController(
      text: AppLang.t(
        'এই খাতে আরও ৳$shortfall প্রয়োজন, আপনি চাইলে অংশ নিতে পারেন। জাযাকুমুল্লাহু খাইরান',
        'An additional ৳$shortfall is needed for this fund — you are welcome to contribute. JazakAllahu Khayran',
      ),
    );
    String target = 'ALL';
    String? selectedDonorId;
    List<Map<String, dynamic>> donors = [];
    bool loadingDonors = true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          if (loadingDonors) {
            _api.get('adminListAllDonors').then((res) {
              if (res['ok'] == true) {
                donors = (res['data'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .where((d) => d['status'] == 'ACTIVE')
                    .toList();
              }
              setDlg(() => loadingDonors = false);
            });
          }
          return AlertDialog(
            title: Text(AppLang.t('দানকারীদের জানান', 'Notify Donors')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLang.t('ফান্ড: $ft', 'Fund: $ft')),
                  const SizedBox(height: 10),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'ALL',
                    groupValue: target,
                    title: Text(AppLang.t('সব দানকারী', 'All donors')),
                    onChanged: (v) => setDlg(() => target = v!),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'SPECIFIC',
                    groupValue: target,
                    title: Text(AppLang.t('নির্দিষ্ট দানকারী', 'Specific donor')),
                    onChanged: (v) => setDlg(() => target = v!),
                  ),
                  if (target == 'SPECIFIC')
                    loadingDonors
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                        : DropdownButtonFormField<String>(
                            initialValue: selectedDonorId,
                            decoration: InputDecoration(labelText: AppLang.t('দানকারী', 'Donor')),
                            items: donors.map((d) => DropdownMenuItem(
                                  value: d['id'] as String,
                                  child: Text('${d['name_bn'] ?? ''} (${d['phone'] ?? ''})'),
                                )).toList(),
                            onChanged: (v) => setDlg(() => selectedDonorId = v),
                          ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: messageCtrl,
                    minLines: 3,
                    maxLines: 6,
                    decoration: InputDecoration(labelText: AppLang.t('মেসেজ', 'Message')),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLang.t('বাতিল', 'Cancel'))),
              FilledButton(
                onPressed: (target == 'SPECIFIC' && selectedDonorId == null)
                    ? null
                    : () async {
                        final res = await _api.post('sendDonorNotification', {
                          'user_role': SessionService.role,
                          'payload': {
                            'target': target,
                            if (target == 'SPECIFIC') 'donor_id': selectedDonorId,
                            'fund_type': fundType,
                            'message_bn': messageCtrl.text.trim(),
                          },
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res['ok'] == true
                                ? AppLang.t('পাঠানো হয়েছে', 'Sent')
                                : (res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
                          ));
                        }
                      },
                child: Text(AppLang.t('পাঠান', 'Send')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openDonorLinkSheet(Map<String, dynamic> expense) async {
    final expenseId = expense['id'] as String?;
    if (expenseId == null) return;
    final fundType = (expense['fund_type'] as String?) ?? '';

    List<Map<String, dynamic>> txns = [];
    bool loading = true;
    String? selectedTxnId;
    final amountCtrl = TextEditingController(text: '${expense['amount'] ?? ''}');
    final noteCtrl = TextEditingController();

    Future<void> load() async {
      final res = await _api.get('adminListDonorTransactions');
      if (res['ok'] == true) {
        final raw = res['data'] as List? ?? [];
        txns = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((t) => t['status'] == 'CONFIRMED' && t['fund_type'] == fundType)
            .toList();
      }
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          if (loading) {
            load().then((_) {
              loading = false;
              setSheet(() {});
            });
          }
          return Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLang.t('দানকারীর তহবিল থেকে ব্যয় লিংক করুন', 'Link expense to donor fund'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (txns.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(AppLang.t(
                        'এই ফান্ডে নিশ্চিতকৃত কোনো দানকারী লেনদেন নেই',
                        'No confirmed donor transaction for this fund')),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: selectedTxnId,
                    decoration: InputDecoration(labelText: AppLang.t('দানকারী লেনদেন', 'Donor transaction')),
                    items: txns.map((t) => DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text('${t['donor_name_bn'] ?? ''} • ৳${t['amount_bdt']} • ${(t['created_at'] as String? ?? '').split('T').first}'),
                    )).toList(),
                    onChanged: (v) => setSheet(() => selectedTxnId = v),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: AppLang.t('ব্যবহৃত পরিমাণ (৳)', 'Amount used (৳)')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(labelText: AppLang.t('মন্তব্য (ঐচ্ছিক)', 'Note (optional)')),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (selectedTxnId == null)
                        ? null
                        : () async {
                            final res = await _api.post('linkExpenseToDonor', {
                              'user_role': SessionService.role,
                              'payload': {
                                'expense_id': expenseId,
                                'donor_txn_id': selectedTxnId,
                                'amount_used': double.tryParse(amountCtrl.text.trim()) ?? 0,
                                'notes': noteCtrl.text.trim(),
                              },
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(res['ok'] == true
                                    ? AppLang.t('লিংক করা হয়েছে', 'Linked')
                                    : (res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
                              ));
                            }
                          },
                    child: Text(AppLang.t('লিংক করুন', 'Link')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
                  FundTypeDropdown(
                    value: _fundType,
                    onChanged: (v) => setState(() => _fundType = v),
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
                      trailing: PopupMenuButton<String>(
                        tooltip: AppLang.t('দানকারীর তহবিল থেকে ব্যয়', 'Link to donor fund'),
                        icon: const Icon(Icons.volunteer_activism_outlined),
                        onSelected: (v) {
                          if (v == 'auto') _openAutoDeductSheet(r);
                          if (v == 'manual') _openDonorLinkSheet(r);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'auto',
                            child: Text(AppLang.t('স্বয়ংক্রিয় বণ্টন', 'Auto-split across donors')),
                          ),
                          PopupMenuItem(
                            value: 'manual',
                            child: Text(AppLang.t('নির্দিষ্ট দানকারী বেছে নিন', 'Pick a specific donor')),
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

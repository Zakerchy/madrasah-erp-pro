import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_lang.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';
import '../../shared/widgets/themed_date_picker.dart';

class FeeDuesScreen extends StatefulWidget {
  const FeeDuesScreen({super.key});

  @override
  State<FeeDuesScreen> createState() => _FeeDuesScreenState();
}

class _FeeDuesScreenState extends State<FeeDuesScreen> {
  final _api = ApiService();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  bool _loading = true;
  bool _saving = false;
  int _tabIndex = 0;

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _dues = [];
  Map<String, dynamic> _totals = {};

  String _classId = '';
  String _monthKey = '';
  String _studentId = '';
  String _planId = '';

  final _planName = TextEditingController();
  final _planAmount = TextEditingController();
  final _planFrom = TextEditingController();
  final _planTo = TextEditingController();
  final _planNotes = TextEditingController();

  final _payAmount = TextEditingController();
  final _payReference = TextEditingController();
  final _payNotes = TextEditingController();
  String _payDate = '';
  String _fundType = 'GENERAL';

  final _waiverAmount = TextEditingController();
  final _waiverReason = TextEditingController();
  final _waiverNotes = TextEditingController();

  bool get _canWrite =>
      SessionService.role == 'ADMIN' || SessionService.role == 'ACCOUNTANT';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _planFrom.text = _monthKey;
    _payDate = _dateFormat.format(now);
    _loadAll();
  }

  @override
  void dispose() {
    _planName.dispose();
    _planAmount.dispose();
    _planFrom.dispose();
    _planTo.dispose();
    _planNotes.dispose();
    _payAmount.dispose();
    _payReference.dispose();
    _payNotes.dispose();
    _waiverAmount.dispose();
    _waiverReason.dispose();
    _waiverNotes.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final base = await Future.wait([
        _api.get('listClasses'),
        _api.get('listStudents', query: {'limit': 1000}),
        _api.get('listFeePlans'),
      ]);
      if (base[0]['ok'] == true) _classes = _rows(base[0]);
      if (base[1]['ok'] == true) _students = _rows(base[1]);
      if (base[2]['ok'] == true) _plans = _rows(base[2]);
      _classId = _validId(_classes, _classId, allowEmpty: true);
      _studentId = _validId(_filteredStudents(), _studentId, allowEmpty: true);
      await _loadDues();
    } catch (_) {
      _snack(AppLang.t('ফি data লোড করা যায়নি', 'Could not load fee data'));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadDues() async {
    final res = await _api.get('listFeeDues', query: {
      'month_key': _monthKey,
      if (_classId.isNotEmpty) 'class_id': _classId,
      if (_studentId.isNotEmpty) 'student_id': _studentId,
    });
    if (res['ok'] == true) {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      _dues = (data['rows'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _totals = Map<String, dynamic>.from(data['totals'] as Map? ?? {});
    }
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> res) {
    return (res['data'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  String _validId(List<Map<String, dynamic>> rows, String current,
      {bool allowEmpty = false}) {
    if (allowEmpty && current.isEmpty) return '';
    if (rows.any((r) => r['id'].toString() == current)) return current;
    return rows.isEmpty ? '' : rows.first['id'].toString();
  }

  List<Map<String, dynamic>> _filteredStudents() {
    return _students.where((s) {
      if (_classId.isNotEmpty && s['class_id'].toString() != _classId) {
        return false;
      }
      if (s['status']?.toString() == 'INACTIVE') return false;
      return true;
    }).toList();
  }

  String _nameById(List<Map<String, dynamic>> rows, String id,
      {String key = 'name'}) {
    final match = rows.where((r) => r['id'].toString() == id);
    if (match.isEmpty) return id.isEmpty ? '-' : id;
    return (match.first[key] ?? match.first['name_bn'] ?? id).toString();
  }

  Future<void> _pickPayDate() async {
    final selected = await showThemedDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_payDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (selected == null) return;
    setState(() => _payDate = _dateFormat.format(selected));
  }

  Future<void> _savePlan() async {
    if (_planName.text.trim().isEmpty || _planAmount.text.trim().isEmpty) {
      _snack(AppLang.t(
          'Plan name ও amount প্রয়োজন', 'Plan name and amount are required'));
      return;
    }
    await _saveAction(
        'upsertFeePlan',
        {
          if (_planId.isNotEmpty) 'id': _planId,
          'name': _planName.text.trim(),
          'class_id': _classId,
          'month_from': _planFrom.text.trim(),
          'month_to': _planTo.text.trim(),
          'amount': double.tryParse(_planAmount.text.trim()) ?? 0,
          'frequency': 'MONTHLY',
          'status': 'ACTIVE',
          'notes': _planNotes.text.trim(),
          'updated_by': SessionService.userId,
        },
        AppLang.t('Fee plan সংরক্ষিত', 'Fee plan saved'));
    _planId = '';
    _planName.clear();
    _planAmount.clear();
    _planNotes.clear();
  }

  Future<void> _recordPayment() async {
    if (_studentId.isEmpty || _payAmount.text.trim().isEmpty) {
      _snack(AppLang.t(
          'শিক্ষার্থী ও amount প্রয়োজন', 'Student and amount are required'));
      return;
    }
    await _saveAction(
        'recordFeePayment',
        {
          'student_id': _studentId,
          'month_key': _monthKey,
          'amount': double.tryParse(_payAmount.text.trim()) ?? 0,
          'payment_date': _payDate,
          'reference': _payReference.text.trim(),
          'fund_type': _fundType,
          'notes': _payNotes.text.trim(),
          'updated_by': SessionService.userId,
        },
        AppLang.t('Payment সংরক্ষিত', 'Payment saved'));
    _payAmount.clear();
    _payReference.clear();
    _payNotes.clear();
  }

  Future<void> _saveWaiver() async {
    if (_studentId.isEmpty ||
        _waiverAmount.text.trim().isEmpty ||
        _waiverReason.text.trim().isEmpty) {
      _snack(AppLang.t('শিক্ষার্থী, amount ও reason প্রয়োজন',
          'Student, amount, and reason are required'));
      return;
    }
    await _saveAction(
        'upsertFeeWaiver',
        {
          'student_id': _studentId,
          'month_key': _monthKey,
          'amount': double.tryParse(_waiverAmount.text.trim()) ?? 0,
          'reason': _waiverReason.text.trim(),
          'notes': _waiverNotes.text.trim(),
          'updated_by': SessionService.userId,
        },
        AppLang.t('Waiver সংরক্ষিত', 'Waiver saved'));
    _waiverAmount.clear();
    _waiverReason.clear();
    _waiverNotes.clear();
  }

  Future<void> _saveAction(
      String action, Map<String, dynamic> payload, String success) async {
    if (!_canWrite) {
      _snack(AppLang.t(
          'আপনার লেখার অনুমতি নেই', 'You do not have write permission'));
      return;
    }
    setState(() => _saving = true);
    final res = await _api.post(action, {
      'user_role': SessionService.role,
      'user_id': SessionService.userId,
      'payload': payload,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['ok'] == true) {
      await _loadAll();
      _snack(res['queued'] == true
          ? AppLang.t('অফলাইনে সংরক্ষিত। অনলাইনে sync হবে।',
              'Saved offline. It will sync online.')
          : success);
    } else {
      _snack('${res['message'] ?? res['error'] ?? 'Failed'}');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, isEn, _) => BaseScaffold(
        title: AppLang.t('ফি ও বকেয়া', 'Fees & Dues'),
        actions: [
          IconButton(
              onPressed: _loading ? null : _loadAll,
              icon: const Icon(Icons.refresh)),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                return ListView(
                  padding: EdgeInsets.all(wide ? 24 : 14),
                  children: [
                    _hero(wide),
                    const SizedBox(height: 14),
                    _filters(),
                    const SizedBox(height: 14),
                    _tabs(),
                    const SizedBox(height: 14),
                    switch (_tabIndex) {
                      0 => _duesPanel(),
                      1 => _planPanel(),
                      _ => wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Expanded(child: _paymentPanel()),
                                  const SizedBox(width: 14),
                                  Expanded(child: _waiverPanel()),
                                ])
                          : Column(children: [
                              _paymentPanel(),
                              const SizedBox(height: 14),
                              _waiverPanel()
                            ]),
                    },
                  ],
                );
              }),
      ),
    );
  }

  Widget _hero(bool wide) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B2010), Color(0xFF9A5B23), Color(0xFFE9C46A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(wide ? 24 : 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              AppLang.t('Fee, Dues & Scholarship States',
                  'Fee, Dues & Scholarship States'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            AppLang.t(
                'Monthly fee plan, payment, waiver এবং due automation এক জায়গায়।',
                'Monthly fee plans, payments, waivers, and due automation in one workspace.'),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _metric(AppLang.t('Planned', 'Planned'),
                _totals['planned_amount'] ?? 0),
            _metric(AppLang.t('Paid', 'Paid'), _totals['paid_amount'] ?? 0),
            _metric(
                AppLang.t('Waived', 'Waived'), _totals['waived_amount'] ?? 0),
            _metric(AppLang.t('Due', 'Due'), _totals['due_amount'] ?? 0),
          ]),
        ]),
      ),
    );
  }

  Widget _metric(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text('$label: ৳$value',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  Widget _filters() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: 220, child: _monthField()),
          SizedBox(width: 240, child: _classDropdown()),
          SizedBox(width: 260, child: _studentDropdown()),
          FilledButton.tonalIcon(
              onPressed: _loadAll,
              icon: const Icon(Icons.search),
              label: Text(AppLang.t('দেখুন', 'Load'))),
        ]),
      ),
    );
  }

  Widget _monthField() {
    return TextField(
      controller: TextEditingController(text: _monthKey),
      decoration: InputDecoration(
          labelText: AppLang.t('মাস (YYYY-MM)', 'Month (YYYY-MM)')),
      onSubmitted: (v) {
        setState(() => _monthKey = v.trim());
        _loadAll();
      },
    );
  }

  Widget _classDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
          _classes.any((r) => r['id'].toString() == _classId) ? _classId : '',
      items: [
        DropdownMenuItem(
            value: '', child: Text(AppLang.t('সব শ্রেণি', 'All classes'))),
        ..._classes.map((r) => DropdownMenuItem(
            value: r['id'].toString(),
            child: Text(r['name']?.toString() ?? '-'))),
      ],
      onChanged: (v) {
        setState(() {
          _classId = v ?? '';
          _studentId = '';
        });
        _loadAll();
      },
      decoration: InputDecoration(labelText: AppLang.t('শ্রেণি', 'Class')),
    );
  }

  Widget _studentDropdown() {
    final students = _filteredStudents();
    return DropdownButtonFormField<String>(
      initialValue: students.any((r) => r['id'].toString() == _studentId)
          ? _studentId
          : '',
      items: [
        DropdownMenuItem(
            value: '', child: Text(AppLang.t('সব শিক্ষার্থী', 'All students'))),
        ...students.map((r) => DropdownMenuItem(
            value: r['id'].toString(),
            child: Text(r['name_bn']?.toString() ?? '-'))),
      ],
      onChanged: (v) {
        setState(() => _studentId = v ?? '');
        _loadAll();
      },
      decoration:
          InputDecoration(labelText: AppLang.t('শিক্ষার্থী', 'Student')),
    );
  }

  Widget _tabs() {
    final tabs = [
      (Icons.receipt_long, AppLang.t('বকেয়া', 'Dues')),
      (Icons.tune, AppLang.t('Fee Plan', 'Fee Plan')),
      (Icons.payments, AppLang.t('Payment/Waiver', 'Payment/Waiver')),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
            tabs.length,
            (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _tabIndex == i,
                    avatar: Icon(tabs[i].$1, size: 18),
                    label: Text(tabs[i].$2),
                    onSelected: (_) => setState(() => _tabIndex = i),
                  ),
                )),
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }

  Widget _duesPanel() {
    return _panel(
      AppLang.t('বকেয়া তালিকা', 'Dues List'),
      _dues.isEmpty
          ? Text(AppLang.t(
              'এই filter-এ কোনো due data নেই।', 'No due data for this filter.'))
          : Column(
              children: _dues
                  .map((r) => Card(
                        elevation: 0,
                        child: ListTile(
                          title: Text(r['student_name']?.toString() ?? '-'),
                          subtitle: Text(
                              '${AppLang.t('Planned', 'Planned')}: ৳${r['planned_amount']} • ${AppLang.t('Paid', 'Paid')}: ৳${r['paid_amount']} • ${AppLang.t('Waived', 'Waived')}: ৳${r['waived_amount']}'),
                          trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('৳${r['due_amount'] ?? 0}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                Text(r['scholarship_due_state']?.toString() ??
                                    ''),
                              ]),
                          onTap: () => setState(() =>
                              _studentId = r['student_id']?.toString() ?? ''),
                        ),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _planPanel() {
    return _panel(
      AppLang.t('Fee Plan Setup', 'Fee Plan Setup'),
      Column(children: [
        TextField(
            controller: _planName,
            decoration: InputDecoration(
                labelText: AppLang.t('Plan name', 'Plan name'))),
        const SizedBox(height: 8),
        TextField(
            controller: _planAmount,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: AppLang.t('Amount', 'Amount'))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _planFrom,
                  decoration: InputDecoration(
                      labelText: AppLang.t('From month', 'From month')))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: _planTo,
                  decoration: InputDecoration(
                      labelText: AppLang.t(
                          'To month optional', 'To month optional')))),
        ]),
        const SizedBox(height: 8),
        TextField(
            controller: _planNotes,
            decoration:
                InputDecoration(labelText: AppLang.t('Notes', 'Notes'))),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
              onPressed: !_canWrite || _saving ? null : _savePlan,
              icon: const Icon(Icons.save),
              label: Text(AppLang.t('Plan save', 'Save plan'))),
        ),
        const Divider(height: 24),
        ..._plans.map((p) => ListTile(
              title: Text(p['name']?.toString() ?? '-'),
              subtitle: Text(
                  '${_nameById(_classes, p['class_id']?.toString() ?? '')} • ৳${p['amount'] ?? 0} • ${p['month_from'] ?? '-'} → ${p['month_to'] ?? ''}'),
              onTap: () => setState(() {
                _planId = p['id']?.toString() ?? '';
                _planName.text = p['name']?.toString() ?? '';
                _classId = p['class_id']?.toString() ?? '';
                _planAmount.text = p['amount']?.toString() ?? '';
                _planFrom.text = p['month_from']?.toString() ?? _monthKey;
                _planTo.text = p['month_to']?.toString() ?? '';
                _planNotes.text = p['notes']?.toString() ?? '';
              }),
            )),
      ]),
    );
  }

  Widget _paymentPanel() {
    return _panel(
      AppLang.t('Payment Entry', 'Payment Entry'),
      Column(children: [
        _studentDropdown(),
        const SizedBox(height: 8),
        TextField(
            controller: _payAmount,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: AppLang.t('Amount', 'Amount'))),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: _pickPayDate,
            icon: const Icon(Icons.calendar_month),
            label: Text('${AppLang.t('Date', 'Date')}: $_payDate')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _fundType,
          items: ['GENERAL', 'CONSTRUCTION', 'JAKAT', 'SCHOLARSHIP']
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (v) => setState(() => _fundType = v ?? 'GENERAL'),
          decoration: InputDecoration(labelText: AppLang.t('Fund', 'Fund')),
        ),
        const SizedBox(height: 8),
        TextField(
            controller: _payReference,
            decoration: InputDecoration(
                labelText: AppLang.t('Reference', 'Reference'))),
        TextField(
            controller: _payNotes,
            decoration:
                InputDecoration(labelText: AppLang.t('Notes', 'Notes'))),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
              onPressed: !_canWrite || _saving ? null : _recordPayment,
              icon: const Icon(Icons.payments),
              label: Text(AppLang.t('Payment save', 'Save payment'))),
        ),
      ]),
    );
  }

  Widget _waiverPanel() {
    return _panel(
      AppLang.t(
          'Waiver / Scholarship Due State', 'Waiver / Scholarship Due State'),
      Column(children: [
        TextField(
            controller: _waiverAmount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: AppLang.t('Waiver amount', 'Waiver amount'))),
        const SizedBox(height: 8),
        TextField(
            controller: _waiverReason,
            decoration: InputDecoration(
                labelText: AppLang.t('Reason required', 'Reason required'))),
        TextField(
            controller: _waiverNotes,
            decoration:
                InputDecoration(labelText: AppLang.t('Notes', 'Notes'))),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
              onPressed: !_canWrite || _saving ? null : _saveWaiver,
              icon: const Icon(Icons.volunteer_activism),
              label: Text(AppLang.t('Waiver save', 'Save waiver'))),
        ),
      ]),
    );
  }
}

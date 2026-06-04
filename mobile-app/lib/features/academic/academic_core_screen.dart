import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_lang.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';
import '../../shared/widgets/themed_date_picker.dart';

class AcademicCoreScreen extends StatefulWidget {
  const AcademicCoreScreen({super.key});

  @override
  State<AcademicCoreScreen> createState() => _AcademicCoreScreenState();
}

class _AcademicCoreScreenState extends State<AcademicCoreScreen> {
  final _api = ApiService();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  bool _loading = true;
  bool _saving = false;
  int _tabIndex = 0;

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _examTerms = [];
  List<Map<String, dynamic>> _examMarks = [];
  List<Map<String, dynamic>> _summaryRows = [];

  String _classId = '';
  String _sectionId = '';
  String _attendanceDate = '';
  final Map<String, String> _attendanceStatus = {};
  final Map<String, TextEditingController> _attendanceNotes = {};

  String _examTermId = '';
  final _examName = TextEditingController();
  String _examStart = '';
  String _examEnd = '';
  final _examNotes = TextEditingController();

  String _markStudentId = '';
  String _markSubjectId = '';
  final _marksObtained = TextEditingController();
  final _maxMarks = TextEditingController(text: '100');
  final _markNotes = TextEditingController();

  bool get _canWrite =>
      SessionService.role == 'ADMIN' || SessionService.role == 'ACCOUNTANT';
  bool get _canRecordAttendance =>
      _canWrite || SessionService.role == 'FIELD_USER';

  @override
  void initState() {
    super.initState();
    final today = _dateFormat.format(DateTime.now());
    _attendanceDate = today;
    _examStart = today;
    _examEnd = today;
    _loadAll();
  }

  @override
  void dispose() {
    _examName.dispose();
    _examNotes.dispose();
    _marksObtained.dispose();
    _maxMarks.dispose();
    _markNotes.dispose();
    for (final c in _attendanceNotes.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAll({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      final base = await Future.wait([
        _api.get('listClasses', forceRefresh: forceRefresh),
        _api.get('listSections', forceRefresh: forceRefresh),
        _api.get('listSubjects', forceRefresh: forceRefresh),
        _api.get('listStudents',
            query: {'limit': 1000}, forceRefresh: forceRefresh),
      ]);
      if (base[0]['ok'] == true) _classes = _rows(base[0]);
      if (base[1]['ok'] == true) _sections = _rows(base[1]);
      if (base[2]['ok'] == true) _subjects = _rows(base[2]);
      if (base[3]['ok'] == true) _students = _rows(base[3]);
      _classId = _validId(_classes, _classId);
      _sectionId = _validId(_filteredSections(), _sectionId, allowEmpty: true);
      await _loadAcademicState(forceRefresh: forceRefresh);
    } catch (_) {
      _snack(AppLang.t('Academic core data লোড করা যায়নি',
          'Could not load academic core data'));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadAcademicState({bool forceRefresh = false}) async {
    final responses = await Future.wait([
      _api.get('listAttendance', query: {
        'attendance_date': _attendanceDate,
        if (_classId.isNotEmpty) 'class_id': _classId,
        if (_sectionId.isNotEmpty) 'section_id': _sectionId,
      }, forceRefresh: forceRefresh),
      _api.get('listExamTerms', query: {
        if (_classId.isNotEmpty) 'class_id': _classId,
        if (_sectionId.isNotEmpty) 'section_id': _sectionId,
      }, forceRefresh: forceRefresh),
      _api.get('listExamMarks', query: {
        if (_examTermId.isNotEmpty) 'exam_term_id': _examTermId,
        if (_classId.isNotEmpty) 'class_id': _classId,
      }, forceRefresh: forceRefresh),
    ]);
    if (responses[0]['ok'] == true) _attendance = _rows(responses[0]);
    if (responses[1]['ok'] == true) _examTerms = _rows(responses[1]);
    _examTermId = _validId(_examTerms, _examTermId, allowEmpty: true);
    if (responses[2]['ok'] == true) _examMarks = _rows(responses[2]);
    await _loadResultSummary(forceRefresh: forceRefresh);
    _syncAttendanceDraft();
    _syncMarkDefaults();
  }

  Future<void> _loadResultSummary({bool forceRefresh = false}) async {
    if (_examTermId.isEmpty) {
      _summaryRows = [];
      return;
    }
    final res = await _api.get('resultSummary', query: {
      'exam_term_id': _examTermId,
      if (_classId.isNotEmpty) 'class_id': _classId,
      if (_sectionId.isNotEmpty) 'section_id': _sectionId,
    }, forceRefresh: forceRefresh);
    if (res['ok'] == true) {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      _summaryRows = (data['rows'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
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
      if (_sectionId.isNotEmpty && s['section_id'].toString() != _sectionId) {
        return false;
      }
      if (s['status']?.toString() == 'INACTIVE') return false;
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _filteredSections() {
    return _sections.where((s) {
      if (_classId.isNotEmpty && s['class_id'].toString() != _classId) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _filteredSubjects() {
    return _subjects.where((s) {
      if (_classId.isNotEmpty && s['class_id'].toString() != _classId) {
        return false;
      }
      return true;
    }).toList();
  }

  String _nameById(List<Map<String, dynamic>> rows, String id,
      {String key = 'name'}) {
    final match = rows.where((r) => r['id'].toString() == id);
    if (match.isEmpty) return id.isEmpty ? '-' : id;
    return (match.first[key] ?? match.first['name_bn'] ?? id).toString();
  }

  void _syncAttendanceDraft() {
    final existingByStudent = {
      for (final r in _attendance) r['student_id'].toString(): r,
    };
    for (final student in _filteredStudents()) {
      final id = student['id'].toString();
      _attendanceStatus[id] = existingByStudent[id]?['status']?.toString() ??
          _attendanceStatus[id] ??
          'PRESENT';
      _attendanceNotes.putIfAbsent(
        id,
        () => TextEditingController(
          text: existingByStudent[id]?['notes']?.toString() ?? '',
        ),
      );
    }
  }

  void _syncMarkDefaults() {
    final students = _filteredStudents();
    final subjects = _filteredSubjects();
    _markStudentId = _validId(students, _markStudentId, allowEmpty: true);
    _markSubjectId = _validId(subjects, _markSubjectId, allowEmpty: true);
  }

  Future<void> _changeFilter({String? classId, String? sectionId}) async {
    setState(() {
      if (classId != null) {
        _classId = classId;
        _sectionId = '';
      }
      if (sectionId != null) _sectionId = sectionId;
    });
    await _loadAcademicState();
    if (mounted) setState(() {});
  }

  Future<void> _pickDate(String current, ValueChanged<String> setValue) async {
    final now = DateTime.now();
    final selected = await showThemedDatePicker(
      context: context,
      initialDate: DateTime.tryParse(current) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (selected == null) return;
    setValue(_dateFormat.format(selected));
  }

  Future<void> _saveAttendance() async {
    final students = _filteredStudents();
    if (_classId.isEmpty || students.isEmpty) {
      _snack(AppLang.t(
          'শ্রেণি ও শিক্ষার্থী প্রয়োজন', 'Class and students are required'));
      return;
    }
    await _saveAction(
      'saveAttendance',
      {
        'attendance_date': _attendanceDate,
        'class_id': _classId,
        'section_id': _sectionId,
        'rows': students
            .map((s) => {
                  'student_id': s['id'].toString(),
                  'status': _attendanceStatus[s['id'].toString()] ?? 'PRESENT',
                  'notes':
                      _attendanceNotes[s['id'].toString()]?.text.trim() ?? '',
                })
            .toList(),
      },
      AppLang.t('হাজিরা সংরক্ষিত', 'Attendance saved'),
    );
  }

  Future<void> _saveExamTerm() async {
    if (_examName.text.trim().isEmpty || _classId.isEmpty) {
      _snack(AppLang.t(
          'পরীক্ষার নাম ও শ্রেণি প্রয়োজন', 'Exam name and class are required'));
      return;
    }
    await _saveAction(
      'upsertExamTerm',
      {
        if (_examTermId.isNotEmpty) 'id': _examTermId,
        'name': _examName.text.trim(),
        'class_id': _classId,
        'section_id': _sectionId,
        'start_date': _examStart,
        'end_date': _examEnd,
        'status': 'ACTIVE',
        'notes': _examNotes.text.trim(),
        'updated_by': SessionService.userId,
      },
      AppLang.t('পরীক্ষা সংরক্ষিত', 'Exam term saved'),
    );
    _examName.clear();
    _examNotes.clear();
  }

  Future<void> _saveMark() async {
    if (_examTermId.isEmpty ||
        _markStudentId.isEmpty ||
        _markSubjectId.isEmpty) {
      _snack(AppLang.t('পরীক্ষা, শিক্ষার্থী ও বিষয় নির্বাচন করুন',
          'Select exam, student, and subject'));
      return;
    }
    await _saveAction(
      'saveExamMark',
      {
        'exam_term_id': _examTermId,
        'student_id': _markStudentId,
        'subject_id': _markSubjectId,
        'class_id': _classId,
        'marks_obtained': double.tryParse(_marksObtained.text.trim()) ?? 0,
        'max_marks': double.tryParse(_maxMarks.text.trim()) ?? 100,
        'notes': _markNotes.text.trim(),
        'updated_by': SessionService.userId,
      },
      AppLang.t('নম্বর সংরক্ষিত', 'Mark saved'),
    );
    _marksObtained.clear();
    _markNotes.clear();
  }

  Future<void> _saveAction(
      String action, Map<String, dynamic> payload, String success) async {
    if (!_canWrite && action != 'saveAttendance') {
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
      await _loadAcademicState();
      if (mounted) setState(() {});
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
        title: AppLang.t('একাডেমিক কোর', 'Academic Core'),
        actions: [
          IconButton(
            tooltip: AppLang.t('রিফ্রেশ', 'Refresh'),
            onPressed: _loading ? null : () => _loadAll(forceRefresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
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
                        0 => _attendanceTab(wide),
                        1 => _examTab(wide),
                        _ => _resultTab(),
                      },
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _hero(bool wide) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF10233F), Color(0xFF1D6B82), Color(0xFFF2C36B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(wide ? 24 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLang.t(
                  'Attendance, Exams & Results', 'Attendance, Exams & Results'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              AppLang.t(
                'দৈনিক হাজিরা, পরীক্ষা সেটআপ, নম্বর এন্ট্রি ও ফলাফল summary এক জায়গায়।',
                'Daily attendance, exam setup, mark entry, and result summaries in one academic command center.',
              ),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _metric(AppLang.t('শিক্ষার্থী', 'Students'),
                    _filteredStudents().length),
                _metric(AppLang.t('হাজিরা row', 'Attendance rows'),
                    _attendance.length),
                _metric(AppLang.t('পরীক্ষা', 'Exams'), _examTerms.length),
                _metric(AppLang.t('নম্বর', 'Marks'), _examMarks.length),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text('$label: $value',
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
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(width: 240, child: _classDropdown()),
            SizedBox(width: 220, child: _sectionDropdown()),
            OutlinedButton.icon(
              onPressed: () => _pickDate(_attendanceDate, (v) async {
                setState(() => _attendanceDate = v);
                await _loadAcademicState();
                if (mounted) setState(() {});
              }),
              icon: const Icon(Icons.calendar_month),
              label: Text(
                  '${AppLang.t('হাজিরা', 'Attendance')}: $_attendanceDate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _classDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
          _classes.any((r) => r['id'].toString() == _classId) ? _classId : null,
      items: _classes
          .map((r) => DropdownMenuItem(
              value: r['id'].toString(),
              child: Text(r['name']?.toString() ?? '-')))
          .toList(),
      onChanged: (v) => _changeFilter(classId: v ?? ''),
      decoration: InputDecoration(labelText: AppLang.t('শ্রেণি', 'Class')),
    );
  }

  Widget _sectionDropdown() {
    final sections = _filteredSections();
    return DropdownButtonFormField<String>(
      initialValue: sections.any((r) => r['id'].toString() == _sectionId)
          ? _sectionId
          : '',
      items: [
        DropdownMenuItem(
            value: '', child: Text(AppLang.t('সব শাখা', 'All sections'))),
        ...sections.map((r) => DropdownMenuItem(
            value: r['id'].toString(),
            child: Text(r['name']?.toString() ?? '-'))),
      ],
      onChanged: (v) => _changeFilter(sectionId: v ?? ''),
      decoration: InputDecoration(labelText: AppLang.t('শাখা', 'Section')),
    );
  }

  Widget _tabs() {
    final tabs = [
      (Icons.fact_check, AppLang.t('হাজিরা', 'Attendance')),
      (Icons.assignment, AppLang.t('পরীক্ষা ও নম্বর', 'Exams & Marks')),
      (Icons.leaderboard, AppLang.t('ফলাফল', 'Results')),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: _tabIndex == i,
              avatar: Icon(tabs[i].$1, size: 18),
              label: Text(tabs[i].$2),
              onSelected: (_) => setState(() => _tabIndex = i),
            ),
          );
        }),
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

  Widget _attendanceTab(bool wide) {
    final students = _filteredStudents();
    return _panel(
      AppLang.t('দৈনিক হাজিরা', 'Daily Attendance'),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (students.isEmpty)
            Text(AppLang.t('এই filter-এ কোনো active শিক্ষার্থী নেই।',
                'No active students for this filter.'))
          else
            ...students.map((s) {
              final id = s['id'].toString();
              return Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: wide
                      ? Row(children: _attendanceRowChildren(s, id, wide))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _attendanceRowChildren(s, id, wide)),
                ),
              );
            }),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: students.isEmpty || !_canRecordAttendance || _saving
                  ? null
                  : _saveAttendance,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(AppLang.t('হাজিরা সংরক্ষণ', 'Save Attendance')),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _attendanceRowChildren(
      Map<String, dynamic> s, String id, bool wide) {
    final name = s['name_bn']?.toString() ?? s['name_en']?.toString() ?? id;
    final statusPicker = SizedBox(
      width: wide ? 170 : double.infinity,
      child: DropdownButtonFormField<String>(
        initialValue: _attendanceStatus[id] ?? 'PRESENT',
        items: ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED']
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (v) =>
            setState(() => _attendanceStatus[id] = v ?? 'PRESENT'),
        decoration: InputDecoration(labelText: AppLang.t('Status', 'Status')),
      ),
    );
    final note = SizedBox(
      width: wide ? 220 : double.infinity,
      child: TextField(
        controller: _attendanceNotes[id],
        decoration: InputDecoration(labelText: AppLang.t('নোট', 'Notes')),
      ),
    );
    return [
      if (wide)
        Expanded(
          flex: 2,
          child: Text(
              '$name • ${AppLang.t('রোল', 'Roll')}: ${s['roll_no'] ?? '-'}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        )
      else
        Text('$name • ${AppLang.t('রোল', 'Roll')}: ${s['roll_no'] ?? '-'}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      if (wide) const SizedBox(width: 10) else const SizedBox(height: 8),
      statusPicker,
      if (wide) const SizedBox(width: 10) else const SizedBox(height: 8),
      note,
    ];
  }

  Widget _examTab(bool wide) {
    final students = _filteredStudents();
    final subjects = _filteredSubjects();
    return wide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _examTermPanel()),
            const SizedBox(width: 14),
            Expanded(child: _markPanel(students, subjects)),
          ])
        : Column(children: [
            _examTermPanel(),
            const SizedBox(height: 14),
            _markPanel(students, subjects)
          ]);
  }

  Widget _examTermPanel() {
    return _panel(
      AppLang.t('পরীক্ষা সেটআপ', 'Exam Setup'),
      Column(children: [
        TextField(
            controller: _examName,
            decoration: InputDecoration(
                labelText: AppLang.t('পরীক্ষার নাম', 'Exam Name'))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _dateButton(
                  AppLang.t('শুরু', 'Start'),
                  _examStart,
                  () => _pickDate(
                      _examStart, (v) => setState(() => _examStart = v)))),
          const SizedBox(width: 8),
          Expanded(
              child: _dateButton(
                  AppLang.t('শেষ', 'End'),
                  _examEnd,
                  () => _pickDate(
                      _examEnd, (v) => setState(() => _examEnd = v)))),
        ]),
        TextField(
            controller: _examNotes,
            decoration: InputDecoration(labelText: AppLang.t('নোট', 'Notes'))),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: !_canWrite || _saving ? null : _saveExamTerm,
            icon: const Icon(Icons.add_task),
            label: Text(AppLang.t('পরীক্ষা সংরক্ষণ', 'Save Exam')),
          ),
        ),
        const Divider(height: 24),
        ..._examTerms.map((e) => ListTile(
              title: Text(e['name']?.toString() ?? '-'),
              subtitle:
                  Text('${e['start_date'] ?? '-'} - ${e['end_date'] ?? '-'}'),
              trailing: _examTermId == e['id'].toString()
                  ? const Icon(Icons.check_circle)
                  : null,
              onTap: () async {
                setState(() {
                  _examTermId = e['id'].toString();
                  _examName.text = e['name']?.toString() ?? '';
                  _examStart = e['start_date']?.toString() ?? _examStart;
                  _examEnd = e['end_date']?.toString() ?? _examEnd;
                  _examNotes.text = e['notes']?.toString() ?? '';
                });
                await _loadAcademicState();
                if (mounted) setState(() {});
              },
            )),
      ]),
    );
  }

  Widget _markPanel(List<Map<String, dynamic>> students,
      List<Map<String, dynamic>> subjects) {
    return _panel(
      AppLang.t('নম্বর এন্ট্রি', 'Mark Entry'),
      Column(children: [
        DropdownButtonFormField<String>(
          initialValue: _examTerms.any((e) => e['id'].toString() == _examTermId)
              ? _examTermId
              : null,
          items: _examTerms
              .map((e) => DropdownMenuItem(
                  value: e['id'].toString(),
                  child: Text(e['name']?.toString() ?? '-')))
              .toList(),
          onChanged: (v) async {
            setState(() => _examTermId = v ?? '');
            await _loadAcademicState();
            if (mounted) setState(() {});
          },
          decoration: InputDecoration(labelText: AppLang.t('পরীক্ষা', 'Exam')),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue:
              students.any((s) => s['id'].toString() == _markStudentId)
                  ? _markStudentId
                  : null,
          items: students
              .map((s) => DropdownMenuItem(
                  value: s['id'].toString(),
                  child: Text(s['name_bn']?.toString() ?? '-')))
              .toList(),
          onChanged: (v) => setState(() => _markStudentId = v ?? ''),
          decoration:
              InputDecoration(labelText: AppLang.t('শিক্ষার্থী', 'Student')),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue:
              subjects.any((s) => s['id'].toString() == _markSubjectId)
                  ? _markSubjectId
                  : null,
          items: subjects
              .map((s) => DropdownMenuItem(
                  value: s['id'].toString(),
                  child: Text(s['name']?.toString() ?? '-')))
              .toList(),
          onChanged: (v) => setState(() => _markSubjectId = v ?? ''),
          decoration: InputDecoration(labelText: AppLang.t('বিষয়', 'Subject')),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: TextField(
                  controller: _marksObtained,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: AppLang.t('প্রাপ্ত নম্বর', 'Marks')))),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: _maxMarks,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: AppLang.t('পূর্ণমান', 'Max')))),
        ]),
        TextField(
            controller: _markNotes,
            decoration: InputDecoration(labelText: AppLang.t('নোট', 'Notes'))),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: !_canWrite || _saving ? null : _saveMark,
            icon: const Icon(Icons.save),
            label: Text(AppLang.t('নম্বর সংরক্ষণ', 'Save Mark')),
          ),
        ),
        const Divider(height: 24),
        ..._examMarks.take(20).map((m) => ListTile(
              title: Text(
                  '${_nameById(_students, m['student_id']?.toString() ?? '', key: 'name_bn')} • ${_nameById(_subjects, m['subject_id']?.toString() ?? '')}'),
              subtitle: Text(
                  '${m['marks_obtained'] ?? 0}/${m['max_marks'] ?? 0} • ${m['grade'] ?? ''}'),
            )),
      ]),
    );
  }

  Widget _dateButton(String label, String value, VoidCallback onTap) {
    return OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_month),
        label: Text('$label: $value'));
  }

  Widget _resultTab() {
    return _panel(
      AppLang.t('ফলাফল summary', 'Result Summary'),
      Column(
        children: [
          if (_examTermId.isEmpty)
            Text(AppLang.t('আগে একটি পরীক্ষা তৈরি/নির্বাচন করুন।',
                'Create or select an exam first.'))
          else if (_summaryRows.isEmpty)
            Text(AppLang.t('নম্বর data পাওয়া যায়নি।', 'No marks data found.'))
          else
            ..._summaryRows.map((r) => Card(
                  elevation: 0,
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${r['grade'] ?? '-'}')),
                    title: Text(r['student_name']?.toString() ?? '-'),
                    subtitle: Text(
                        '${AppLang.t('মোট', 'Total')}: ${r['total_obtained'] ?? 0}/${r['total_max'] ?? 0} • ${r['percent'] ?? 0}% • ${AppLang.t('বিষয়', 'Subjects')}: ${r['subjects_recorded'] ?? 0}'),
                  ),
                )),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/app_permissions.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';
import '../../shared/widgets/themed_date_picker.dart';

class AcademicFoundationScreen extends StatefulWidget {
  const AcademicFoundationScreen({super.key});

  @override
  State<AcademicFoundationScreen> createState() =>
      _AcademicFoundationScreenState();
}

class _AcademicFoundationScreenState extends State<AcademicFoundationScreen> {
  final _api = ApiService();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  bool _loading = true;
  bool _saving = false;
  int _tabIndex = 0;

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _guardians = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _subjects = [];

  String _studentId = '';
  final _studentCode = TextEditingController();
  final _studentNameBn = TextEditingController();
  final _studentNameEn = TextEditingController();
  final _studentRoll = TextEditingController();
  final _studentPhone = TextEditingController();
  final _studentAddress = TextEditingController();
  final _studentNotes = TextEditingController();
  String _studentGender = '';
  String _studentClassId = '';
  String _studentSectionId = '';
  String _studentStatus = 'ACTIVE';
  String _dob = '';
  String _admissionDate = '';

  String _guardianId = '';
  final _guardianName = TextEditingController();
  final _guardianRelation = TextEditingController();
  final _guardianPhone = TextEditingController();
  final _guardianEmail = TextEditingController();
  final _guardianAddress = TextEditingController();
  final _guardianOccupation = TextEditingController();
  String _guardianStudentId = '';
  bool _guardianPrimary = false;
  String _guardianStatus = 'ACTIVE';

  String _classId = '';
  final _className = TextEditingController();
  final _classLevel = TextEditingController();
  final _classSort = TextEditingController();
  final _classNotes = TextEditingController();
  String _classStatus = 'ACTIVE';

  String _sectionId = '';
  final _sectionName = TextEditingController();
  final _sectionCapacity = TextEditingController();
  final _sectionNotes = TextEditingController();
  String _sectionClassId = '';
  String _sectionStatus = 'ACTIVE';

  String _subjectId = '';
  final _subjectName = TextEditingController();
  final _subjectCode = TextEditingController();
  final _subjectSort = TextEditingController();
  final _subjectNotes = TextEditingController();
  String _subjectClassId = '';
  String _subjectStatus = 'ACTIVE';

  bool get _canWrite =>
      SessionService.can(AppPermissions.academicFoundationWrite);

  @override
  void initState() {
    super.initState();
    _admissionDate = _dateFormat.format(DateTime.now());
    _loadAll();
  }

  @override
  void dispose() {
    for (final c in [
      _studentCode,
      _studentNameBn,
      _studentNameEn,
      _studentRoll,
      _studentPhone,
      _studentAddress,
      _studentNotes,
      _guardianName,
      _guardianRelation,
      _guardianPhone,
      _guardianEmail,
      _guardianAddress,
      _guardianOccupation,
      _className,
      _classLevel,
      _classSort,
      _classNotes,
      _sectionName,
      _sectionCapacity,
      _sectionNotes,
      _subjectName,
      _subjectCode,
      _subjectSort,
      _subjectNotes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAll({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      final responses = await Future.wait([
        _api.get('listClasses', forceRefresh: forceRefresh),
        _api.get('listSections', forceRefresh: forceRefresh),
        _api.get('listSubjects', forceRefresh: forceRefresh),
        _api.get('listStudents', forceRefresh: forceRefresh),
        _api.get('listStudentGuardians', forceRefresh: forceRefresh),
      ]);
      if (responses[0]['ok'] == true) _classes = _rows(responses[0]);
      if (responses[1]['ok'] == true) _sections = _rows(responses[1]);
      if (responses[2]['ok'] == true) _subjects = _rows(responses[2]);
      if (responses[3]['ok'] == true) _students = _rows(responses[3]);
      if (responses[4]['ok'] == true) _guardians = _rows(responses[4]);

      if (_classes.isNotEmpty) {
        _studentClassId = _validId(_classes, _studentClassId);
        _sectionClassId = _validId(_classes, _sectionClassId);
        _subjectClassId = _validId(_classes, _subjectClassId);
      }
      if (_sections.isNotEmpty) {
        _studentSectionId = _validId(_sections, _studentSectionId);
      }
      if (_students.isNotEmpty) {
        _guardianStudentId = _validId(_students, _guardianStudentId);
      }
    } catch (_) {
      if (!mounted) return;
      _snack(AppLang.t(
          'Academic data লোড করা যায়নি', 'Could not load academic data'));
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> res) {
    return (res['data'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  String _validId(List<Map<String, dynamic>> rows, String current) {
    if (rows.any((r) => r['id'].toString() == current)) return current;
    return rows.isEmpty ? '' : rows.first['id'].toString();
  }

  String _labelById(List<Map<String, dynamic>> rows, String id,
      {String nameKey = 'name'}) {
    final found = rows.where((r) => r['id'].toString() == id);
    if (found.isEmpty) return id.isEmpty ? '-' : id;
    return (found.first[nameKey] ?? found.first['name_bn'] ?? id).toString();
  }

  Future<void> _pickStudentDate({required bool dob}) async {
    final now = DateTime.now();
    final raw = dob ? _dob : _admissionDate;
    final initial = DateTime.tryParse(raw) ?? now;
    final selected = await showThemedDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 1),
    );
    if (selected == null) return;
    setState(() {
      if (dob) {
        _dob = _dateFormat.format(selected);
      } else {
        _admissionDate = _dateFormat.format(selected);
      }
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _newStudent() {
    setState(() {
      _studentId = '';
      _studentCode.clear();
      _studentNameBn.clear();
      _studentNameEn.clear();
      _studentRoll.clear();
      _studentPhone.clear();
      _studentAddress.clear();
      _studentNotes.clear();
      _studentGender = '';
      _studentClassId = _classes.isEmpty ? '' : _classes.first['id'].toString();
      _studentSectionId =
          _sections.isEmpty ? '' : _sections.first['id'].toString();
      _studentStatus = 'ACTIVE';
      _dob = '';
      _admissionDate = _dateFormat.format(DateTime.now());
    });
  }

  void _editStudent(Map<String, dynamic> r) {
    setState(() {
      _tabIndex = 0;
      _studentId = r['id']?.toString() ?? '';
      _studentCode.text = r['student_code']?.toString() ?? '';
      _studentNameBn.text = r['name_bn']?.toString() ?? '';
      _studentNameEn.text = r['name_en']?.toString() ?? '';
      _studentRoll.text = r['roll_no']?.toString() ?? '';
      _studentPhone.text = r['phone']?.toString() ?? '';
      _studentAddress.text = r['address']?.toString() ?? '';
      _studentNotes.text = r['notes']?.toString() ?? '';
      _studentGender = r['gender']?.toString() ?? '';
      _studentClassId = r['class_id']?.toString() ?? '';
      _studentSectionId = r['section_id']?.toString() ?? '';
      _studentStatus =
          r['status']?.toString() == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
      _dob = r['date_of_birth']?.toString() ?? '';
      _admissionDate =
          r['admission_date']?.toString() ?? _dateFormat.format(DateTime.now());
    });
  }

  Future<void> _saveStudent() async {
    if (_studentNameBn.text.trim().isEmpty || _studentClassId.isEmpty) {
      _snack(AppLang.t('শিক্ষার্থীর নাম ও শ্রেণি প্রয়োজন',
          'Student name and class are required'));
      return;
    }
    final nameCheck = _studentNameBn.text.trim().toLowerCase();
    final hasDuplicateStudent = _students.any((s) {
      if (_studentId.isNotEmpty && s['id']?.toString() == _studentId) return false;
      return (s['name_bn']?.toString().toLowerCase() ?? '') == nameCheck &&
          s['class_id']?.toString() == _studentClassId;
    });
    if (hasDuplicateStudent) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLang.t('সম্ভাব্য ডুপ্লিকেট', 'Possible Duplicate')),
          content: Text(AppLang.t(
            'একই নাম ও শ্রেণিতে শিক্ষার্থী আছে। তবুও সংরক্ষণ করবেন?',
            'A student with the same name and class already exists. Save anyway?',
          )),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLang.t('বাতিল', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLang.t('হ্যাঁ, সংরক্ষণ', 'Yes, Save'))),
          ],
        ),
      );
      if (!mounted || proceed != true) return;
    }
    await _save(
        'upsertStudent',
        {
          if (_studentId.isNotEmpty) 'id': _studentId,
          'student_code': _studentCode.text.trim(),
          'name_bn': _studentNameBn.text.trim(),
          'name_en': _studentNameEn.text.trim(),
          'gender': _studentGender,
          'date_of_birth': _dob,
          'admission_date': _admissionDate,
          'class_id': _studentClassId,
          'section_id': _studentSectionId,
          'roll_no': _studentRoll.text.trim(),
          'status': _studentStatus,
          'phone': _studentPhone.text.trim(),
          'address': _studentAddress.text.trim(),
          'notes': _studentNotes.text.trim(),
          'updated_by': SessionService.userId,
        },
        AppLang.t('শিক্ষার্থী সংরক্ষিত', 'Student saved'),
        _newStudent);
  }

  void _newGuardian() {
    setState(() {
      _guardianId = '';
      _guardianStudentId =
          _students.isEmpty ? '' : _students.first['id'].toString();
      _guardianName.clear();
      _guardianRelation.clear();
      _guardianPhone.clear();
      _guardianEmail.clear();
      _guardianAddress.clear();
      _guardianOccupation.clear();
      _guardianPrimary = false;
      _guardianStatus = 'ACTIVE';
    });
  }

  void _editGuardian(Map<String, dynamic> r) {
    setState(() {
      _tabIndex = 4;
      _guardianId = r['id']?.toString() ?? '';
      _guardianStudentId = r['student_id']?.toString() ?? '';
      _guardianName.text = r['name']?.toString() ?? '';
      _guardianRelation.text = r['relation']?.toString() ?? '';
      _guardianPhone.text = r['phone']?.toString() ?? '';
      _guardianEmail.text = r['email']?.toString() ?? '';
      _guardianAddress.text = r['address']?.toString() ?? '';
      _guardianOccupation.text = r['occupation']?.toString() ?? '';
      _guardianPrimary =
          r['primary_contact']?.toString().toUpperCase() == 'TRUE';
      _guardianStatus =
          r['status']?.toString() == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
    });
  }

  Future<void> _saveGuardian() async {
    if (_guardianStudentId.isEmpty ||
        _guardianName.text.trim().isEmpty ||
        _guardianPhone.text.trim().isEmpty) {
      _snack(AppLang.t('শিক্ষার্থী, অভিভাবক নাম ও ফোন প্রয়োজন',
          'Student, guardian name, and phone are required'));
      return;
    }
    await _save(
        'upsertStudentGuardian',
        {
          if (_guardianId.isNotEmpty) 'id': _guardianId,
          'student_id': _guardianStudentId,
          'name': _guardianName.text.trim(),
          'relation': _guardianRelation.text.trim(),
          'phone': _guardianPhone.text.trim(),
          'email': _guardianEmail.text.trim(),
          'address': _guardianAddress.text.trim(),
          'occupation': _guardianOccupation.text.trim(),
          'primary_contact': _guardianPrimary ? 'TRUE' : 'FALSE',
          'status': _guardianStatus,
          'updated_by': SessionService.userId,
        },
        AppLang.t('অভিভাবক সংরক্ষিত', 'Guardian saved'),
        _newGuardian);
  }

  void _newClass() {
    setState(() {
      _classId = '';
      _className.clear();
      _classLevel.clear();
      _classSort.clear();
      _classNotes.clear();
      _classStatus = 'ACTIVE';
    });
  }

  void _editClass(Map<String, dynamic> r) {
    setState(() {
      _tabIndex = 1;
      _classId = r['id']?.toString() ?? '';
      _className.text = r['name']?.toString() ?? '';
      _classLevel.text = r['level']?.toString() ?? '';
      _classSort.text = r['sort_order']?.toString() ?? '';
      _classNotes.text = r['notes']?.toString() ?? '';
      _classStatus =
          r['status']?.toString() == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
    });
  }

  Future<void> _saveClass() async {
    if (_className.text.trim().isEmpty) {
      _snack(AppLang.t('শ্রেণির নাম প্রয়োজন', 'Class name is required'));
      return;
    }
    await _save(
        'upsertClass',
        {
          if (_classId.isNotEmpty) 'id': _classId,
          'name': _className.text.trim(),
          'level': _classLevel.text.trim(),
          'sort_order': int.tryParse(_classSort.text.trim()) ?? 0,
          'status': _classStatus,
          'notes': _classNotes.text.trim(),
          'updated_by': SessionService.userId,
        },
        AppLang.t('শ্রেণি সংরক্ষিত', 'Class saved'),
        _newClass);
  }

  void _newSection() {
    setState(() {
      _sectionId = '';
      _sectionClassId = _classes.isEmpty ? '' : _classes.first['id'].toString();
      _sectionName.clear();
      _sectionCapacity.clear();
      _sectionNotes.clear();
      _sectionStatus = 'ACTIVE';
    });
  }

  void _editSection(Map<String, dynamic> r) {
    setState(() {
      _tabIndex = 2;
      _sectionId = r['id']?.toString() ?? '';
      _sectionClassId = r['class_id']?.toString() ?? '';
      _sectionName.text = r['name']?.toString() ?? '';
      _sectionCapacity.text = r['capacity']?.toString() ?? '';
      _sectionNotes.text = r['notes']?.toString() ?? '';
      _sectionStatus =
          r['status']?.toString() == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
    });
  }

  Future<void> _saveSection() async {
    if (_sectionClassId.isEmpty || _sectionName.text.trim().isEmpty) {
      _snack(AppLang.t(
          'শ্রেণি ও শাখার নাম প্রয়োজন', 'Class and section name are required'));
      return;
    }
    await _save(
        'upsertSection',
        {
          if (_sectionId.isNotEmpty) 'id': _sectionId,
          'class_id': _sectionClassId,
          'name': _sectionName.text.trim(),
          'capacity': int.tryParse(_sectionCapacity.text.trim()) ?? 0,
          'status': _sectionStatus,
          'notes': _sectionNotes.text.trim(),
          'updated_by': SessionService.userId,
        },
        AppLang.t('শাখা সংরক্ষিত', 'Section saved'),
        _newSection);
  }

  void _newSubject() {
    setState(() {
      _subjectId = '';
      _subjectClassId = _classes.isEmpty ? '' : _classes.first['id'].toString();
      _subjectName.clear();
      _subjectCode.clear();
      _subjectSort.clear();
      _subjectNotes.clear();
      _subjectStatus = 'ACTIVE';
    });
  }

  void _editSubject(Map<String, dynamic> r) {
    setState(() {
      _tabIndex = 3;
      _subjectId = r['id']?.toString() ?? '';
      _subjectClassId = r['class_id']?.toString() ?? '';
      _subjectName.text = r['name']?.toString() ?? '';
      _subjectCode.text = r['code']?.toString() ?? '';
      _subjectSort.text = r['sort_order']?.toString() ?? '';
      _subjectNotes.text = r['notes']?.toString() ?? '';
      _subjectStatus =
          r['status']?.toString() == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
    });
  }

  Future<void> _saveSubject() async {
    if (_subjectClassId.isEmpty || _subjectName.text.trim().isEmpty) {
      _snack(AppLang.t('শ্রেণি ও বিষয়ের নাম প্রয়োজন',
          'Class and subject name are required'));
      return;
    }
    await _save(
        'upsertSubject',
        {
          if (_subjectId.isNotEmpty) 'id': _subjectId,
          'class_id': _subjectClassId,
          'name': _subjectName.text.trim(),
          'code': _subjectCode.text.trim(),
          'sort_order': int.tryParse(_subjectSort.text.trim()) ?? 0,
          'status': _subjectStatus,
          'notes': _subjectNotes.text.trim(),
          'updated_by': SessionService.userId,
        },
        AppLang.t('বিষয় সংরক্ষিত', 'Subject saved'),
        _newSubject);
  }

  Future<void> _save(String action, Map<String, dynamic> payload,
      String successMessage, VoidCallback reset) async {
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
      reset();
      await _loadAll();
      _snack(res['queued'] == true
          ? AppLang.t('অফলাইনে সংরক্ষিত। অনলাইনে sync হবে।',
              'Saved offline. It will sync online.')
          : successMessage);
    } else {
      _snack('${res['message'] ?? res['error'] ?? 'Failed'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, isEn, _) => BaseScaffold(
        title: AppLang.t('শিক্ষার্থী ও একাডেমিক', 'Students & Academic'),
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
                      _tabs(wide),
                      const SizedBox(height: 14),
                      _tabBody(wide),
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
          colors: [Color(0xFF063B2B), Color(0xFF2F7A4F), Color(0xFFE6C36A)],
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
              AppLang.t('Academic Data Foundation', 'Academic Data Foundation'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              AppLang.t(
                'শিক্ষার্থী, শ্রেণি, শাখা, বিষয় ও অভিভাবকের মূল ডেটা এখান থেকে নিয়ন্ত্রণ করুন।',
                'Control core students, classes, sections, subjects, and guardians from one workspace.',
              ),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _metric(AppLang.t('শিক্ষার্থী', 'Students'), _students.length),
                _metric(AppLang.t('শ্রেণি', 'Classes'), _classes.length),
                _metric(AppLang.t('শাখা', 'Sections'), _sections.length),
                _metric(AppLang.t('বিষয়', 'Subjects'), _subjects.length),
                _metric(AppLang.t('অভিভাবক', 'Guardians'), _guardians.length),
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

  Widget _tabs(bool wide) {
    final tabs = [
      (Icons.school, AppLang.t('শিক্ষার্থী', 'Students')),
      (Icons.class_, AppLang.t('শ্রেণি', 'Classes')),
      (Icons.view_column, AppLang.t('শাখা', 'Sections')),
      (Icons.menu_book, AppLang.t('বিষয়', 'Subjects')),
      (Icons.family_restroom, AppLang.t('অভিভাবক', 'Guardians')),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _tabIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              avatar: Icon(tabs[i].$1, size: 18),
              label: Text(tabs[i].$2),
              onSelected: (_) => setState(() => _tabIndex = i),
            ),
          );
        }),
      ),
    );
  }

  Widget _tabBody(bool wide) {
    final form = switch (_tabIndex) {
      0 => _studentForm(),
      1 => _classForm(),
      2 => _sectionForm(),
      3 => _subjectForm(),
      _ => _guardianForm(),
    };
    final list = switch (_tabIndex) {
      0 => _studentList(),
      1 => _classList(),
      2 => _sectionList(),
      3 => _subjectList(),
      _ => _guardianList(),
    };
    if (!wide) {
      return Column(children: [form, const SizedBox(height: 16), list]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: form),
        const SizedBox(width: 16),
        Expanded(flex: 6, child: list),
      ],
    );
  }

  Widget _panel(String title, Widget child, {VoidCallback? onNew}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (onNew != null)
                  TextButton.icon(
                      onPressed: onNew,
                      icon: const Icon(Icons.add),
                      label: Text(AppLang.t('নতুন', 'New'))),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _studentForm() {
    return _panel(
      _studentId.isEmpty
          ? AppLang.t('নতুন শিক্ষার্থী', 'New Student')
          : AppLang.t('শিক্ষার্থী আপডেট', 'Update Student'),
      Column(children: [
        _readOnlyNotice(),
        _field(_studentNameBn, AppLang.t('নাম (বাংলা)', 'Name (Bangla)'),
            required: true),
        _field(_studentNameEn, AppLang.t('নাম (English)', 'Name (English)')),
        _field(_studentCode, AppLang.t('Student ID/Code', 'Student ID/Code')),
        _dropdown(_studentClassId, _classes, AppLang.t('শ্রেণি', 'Class'),
            (v) => setState(() => _studentClassId = v),
            required: true),
        _dropdown(_studentSectionId, _sections, AppLang.t('শাখা', 'Section'),
            (v) => setState(() => _studentSectionId = v)),
        Row(children: [
          Expanded(child: _field(_studentRoll, AppLang.t('রোল', 'Roll'))),
          const SizedBox(width: 10),
          Expanded(
              child: _statusDropdown(
                  _studentStatus, (v) => setState(() => _studentStatus = v))),
        ]),
        _stringDropdown(
            _studentGender,
            [
              ('', AppLang.t('নির্বাচন নয়', 'Not selected')),
              ('Male', AppLang.t('ছাত্র', 'Male')),
              ('Female', AppLang.t('ছাত্রী', 'Female'))
            ],
            AppLang.t('লিঙ্গ', 'Gender'),
            (v) => setState(() => _studentGender = v)),
        Row(children: [
          Expanded(
              child: _dateTile(AppLang.t('জন্ম তারিখ', 'Date of Birth'), _dob,
                  () => _pickStudentDate(dob: true))),
          const SizedBox(width: 10),
          Expanded(
              child: _dateTile(AppLang.t('ভর্তি তারিখ', 'Admission Date'),
                  _admissionDate, () => _pickStudentDate(dob: false))),
        ]),
        _field(_studentPhone, AppLang.t('ফোন', 'Phone'),
            keyboardType: TextInputType.phone),
        _field(_studentAddress, AppLang.t('ঠিকানা', 'Address'), maxLines: 2),
        _field(_studentNotes, AppLang.t('নোট', 'Notes'), maxLines: 2),
        _saveButton(
            _saveStudent, AppLang.t('শিক্ষার্থী সংরক্ষণ', 'Save Student')),
      ]),
      onNew: _newStudent,
    );
  }

  Widget _classForm() {
    return _panel(
      _classId.isEmpty
          ? AppLang.t('নতুন শ্রেণি', 'New Class')
          : AppLang.t('শ্রেণি আপডেট', 'Update Class'),
      Column(children: [
        _readOnlyNotice(),
        _field(_className, AppLang.t('শ্রেণির নাম', 'Class Name'),
            required: true),
        _field(_classLevel, AppLang.t('স্তর', 'Level')),
        _field(_classSort, AppLang.t('Sort order', 'Sort order'),
            keyboardType: TextInputType.number),
        _statusDropdown(_classStatus, (v) => setState(() => _classStatus = v)),
        _field(_classNotes, AppLang.t('নোট', 'Notes'), maxLines: 2),
        _saveButton(_saveClass, AppLang.t('শ্রেণি সংরক্ষণ', 'Save Class')),
      ]),
      onNew: _newClass,
    );
  }

  Widget _sectionForm() {
    return _panel(
      _sectionId.isEmpty
          ? AppLang.t('নতুন শাখা', 'New Section')
          : AppLang.t('শাখা আপডেট', 'Update Section'),
      Column(children: [
        _readOnlyNotice(),
        _dropdown(_sectionClassId, _classes, AppLang.t('শ্রেণি', 'Class'),
            (v) => setState(() => _sectionClassId = v),
            required: true),
        _field(_sectionName, AppLang.t('শাখার নাম', 'Section Name'),
            required: true),
        _field(_sectionCapacity, AppLang.t('Capacity', 'Capacity'),
            keyboardType: TextInputType.number),
        _statusDropdown(
            _sectionStatus, (v) => setState(() => _sectionStatus = v)),
        _field(_sectionNotes, AppLang.t('নোট', 'Notes'), maxLines: 2),
        _saveButton(_saveSection, AppLang.t('শাখা সংরক্ষণ', 'Save Section')),
      ]),
      onNew: _newSection,
    );
  }

  Widget _subjectForm() {
    return _panel(
      _subjectId.isEmpty
          ? AppLang.t('নতুন বিষয়', 'New Subject')
          : AppLang.t('বিষয় আপডেট', 'Update Subject'),
      Column(children: [
        _readOnlyNotice(),
        _dropdown(_subjectClassId, _classes, AppLang.t('শ্রেণি', 'Class'),
            (v) => setState(() => _subjectClassId = v),
            required: true),
        _field(_subjectName, AppLang.t('বিষয়ের নাম', 'Subject Name'),
            required: true),
        _field(_subjectCode, AppLang.t('Code', 'Code')),
        _field(_subjectSort, AppLang.t('Sort order', 'Sort order'),
            keyboardType: TextInputType.number),
        _statusDropdown(
            _subjectStatus, (v) => setState(() => _subjectStatus = v)),
        _field(_subjectNotes, AppLang.t('নোট', 'Notes'), maxLines: 2),
        _saveButton(_saveSubject, AppLang.t('বিষয় সংরক্ষণ', 'Save Subject')),
      ]),
      onNew: _newSubject,
    );
  }

  Widget _guardianForm() {
    return _panel(
      _guardianId.isEmpty
          ? AppLang.t('নতুন অভিভাবক', 'New Guardian')
          : AppLang.t('অভিভাবক আপডেট', 'Update Guardian'),
      Column(children: [
        _readOnlyNotice(),
        _dropdown(
            _guardianStudentId,
            _students,
            AppLang.t('শিক্ষার্থী', 'Student'),
            (v) => setState(() => _guardianStudentId = v),
            nameKey: 'name_bn',
            required: true),
        _field(_guardianName, AppLang.t('অভিভাবকের নাম', 'Guardian Name'),
            required: true),
        _field(_guardianRelation, AppLang.t('সম্পর্ক', 'Relation'),
            required: true),
        _field(_guardianPhone, AppLang.t('ফোন', 'Phone'),
            keyboardType: TextInputType.phone, required: true),
        _field(_guardianEmail, AppLang.t('ইমেইল', 'Email'),
            keyboardType: TextInputType.emailAddress),
        _field(_guardianOccupation, AppLang.t('পেশা', 'Occupation')),
        _field(_guardianAddress, AppLang.t('ঠিকানা', 'Address'), maxLines: 2),
        SwitchListTile.adaptive(
          value: _guardianPrimary,
          onChanged:
              _canWrite ? (v) => setState(() => _guardianPrimary = v) : null,
          title: Text(AppLang.t('Primary contact', 'Primary contact')),
          contentPadding: EdgeInsets.zero,
        ),
        _statusDropdown(
            _guardianStatus, (v) => setState(() => _guardianStatus = v)),
        _saveButton(
            _saveGuardian, AppLang.t('অভিভাবক সংরক্ষণ', 'Save Guardian')),
      ]),
      onNew: _newGuardian,
    );
  }

  Widget _readOnlyNotice() {
    if (_canWrite) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MaterialBanner(
        content: Text(AppLang.t(
            'এই role থেকে শুধু দেখা যাবে।', 'This role can view only.')),
        leading: const Icon(Icons.lock_outline),
        actions: const [SizedBox.shrink()],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {bool required = false, int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        enabled: _canWrite,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: required ? '$label *' : label),
      ),
    );
  }

  Widget _dropdown(String value, List<Map<String, dynamic>> rows, String label,
      ValueChanged<String> onChanged,
      {String nameKey = 'name', bool required = false}) {
    final validValue =
        rows.any((r) => r['id'].toString() == value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: validValue,
        items: rows
            .map((r) => DropdownMenuItem(
                  value: r['id'].toString(),
                  child: Text((r[nameKey] ?? r['name'] ?? r['id']).toString()),
                ))
            .toList(),
        onChanged: _canWrite ? (v) => onChanged(v ?? '') : null,
        decoration: InputDecoration(labelText: required ? '$label *' : label),
      ),
    );
  }

  Widget _stringDropdown(String value, List<(String, String)> options,
      String label, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue:
            options.any((o) => o.$1 == value) ? value : options.first.$1,
        items: options
            .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
            .toList(),
        onChanged: _canWrite ? (v) => onChanged(v ?? '') : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _statusDropdown(String value, ValueChanged<String> onChanged) {
    return _stringDropdown(
        value,
        [
          ('ACTIVE', AppLang.t('Active', 'Active')),
          ('INACTIVE', AppLang.t('Inactive', 'Inactive')),
        ],
        AppLang.t('Status', 'Status'),
        onChanged);
  }

  Widget _dateTile(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton.icon(
        onPressed: _canWrite ? onTap : null,
        icon: const Icon(Icons.calendar_month),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text('$label: ${value.isEmpty ? '-' : value}'),
        ),
      ),
    );
  }

  Widget _saveButton(VoidCallback onPressed, String label) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: _canWrite && !_saving ? onPressed : null,
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.save),
        label: Text(label),
      ),
    );
  }

  Widget _studentList() {
    return _panel(
        AppLang.t('শিক্ষার্থীর তালিকা', 'Student List'),
        _emptyAware(_students, (r) {
          final guardians = _guardians
              .where((g) => g['student_id'].toString() == r['id'].toString())
              .length;
          return ListTile(
            leading: const Icon(Icons.school),
            title: Text(r['name_bn']?.toString() ?? '-'),
            subtitle: Text(
                '${AppLang.t('শ্রেণি', 'Class')}: ${_labelById(_classes, r['class_id']?.toString() ?? '')} • ${AppLang.t('শাখা', 'Section')}: ${_labelById(_sections, r['section_id']?.toString() ?? '')} • ${AppLang.t('রোল', 'Roll')}: ${r['roll_no'] ?? '-'} • ${AppLang.t('অভিভাবক', 'Guardians')}: $guardians'),
            trailing: Text(r['status']?.toString() ?? 'ACTIVE'),
            onTap: () => _editStudent(r),
          );
        }));
  }

  Widget _classList() {
    return _panel(
        AppLang.t('শ্রেণির তালিকা', 'Class List'),
        _emptyAware(_classes, (r) {
          return ListTile(
            leading: const Icon(Icons.class_),
            title: Text(r['name']?.toString() ?? '-'),
            subtitle: Text(
                '${AppLang.t('স্তর', 'Level')}: ${r['level'] ?? '-'} • ${AppLang.t('শিক্ষার্থী', 'Students')}: ${_students.where((s) => s['class_id'].toString() == r['id'].toString()).length}'),
            trailing: Text(r['status']?.toString() ?? 'ACTIVE'),
            onTap: () => _editClass(r),
          );
        }));
  }

  Widget _sectionList() {
    return _panel(
        AppLang.t('শাখার তালিকা', 'Section List'),
        _emptyAware(_sections, (r) {
          return ListTile(
            leading: const Icon(Icons.view_column),
            title: Text(r['name']?.toString() ?? '-'),
            subtitle: Text(
                '${AppLang.t('শ্রেণি', 'Class')}: ${_labelById(_classes, r['class_id']?.toString() ?? '')} • ${AppLang.t('Capacity', 'Capacity')}: ${r['capacity'] ?? 0}'),
            trailing: Text(r['status']?.toString() ?? 'ACTIVE'),
            onTap: () => _editSection(r),
          );
        }));
  }

  Widget _subjectList() {
    return _panel(
        AppLang.t('বিষয়ের তালিকা', 'Subject List'),
        _emptyAware(_subjects, (r) {
          return ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(r['name']?.toString() ?? '-'),
            subtitle: Text(
                '${AppLang.t('শ্রেণি', 'Class')}: ${_labelById(_classes, r['class_id']?.toString() ?? '')} • ${AppLang.t('Code', 'Code')}: ${r['code'] ?? '-'}'),
            trailing: Text(r['status']?.toString() ?? 'ACTIVE'),
            onTap: () => _editSubject(r),
          );
        }));
  }

  Widget _guardianList() {
    return _panel(
        AppLang.t('অভিভাবকের তালিকা', 'Guardian List'),
        _emptyAware(_guardians, (r) {
          return ListTile(
            leading: const Icon(Icons.family_restroom),
            title: Text(r['name']?.toString() ?? '-'),
            subtitle: Text(
                '${AppLang.t('শিক্ষার্থী', 'Student')}: ${_labelById(_students, r['student_id']?.toString() ?? '', nameKey: 'name_bn')} • ${r['relation'] ?? '-'} • ${r['phone'] ?? '-'}'),
            trailing: r['primary_contact']?.toString().toUpperCase() == 'TRUE'
                ? const Icon(Icons.star, color: Color(0xFFE6A700))
                : Text(r['status']?.toString() ?? 'ACTIVE'),
            onTap: () => _editGuardian(r),
          );
        }));
  }

  Widget _emptyAware(List<Map<String, dynamic>> rows,
      Widget Function(Map<String, dynamic>) itemBuilder) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: Text(AppLang.t('এখনো কোনো data নেই', 'No data yet')),
        ),
      );
    }
    return Column(
      children:
          rows.map((r) => Card(elevation: 0, child: itemBuilder(r))).toList(),
    );
  }
}

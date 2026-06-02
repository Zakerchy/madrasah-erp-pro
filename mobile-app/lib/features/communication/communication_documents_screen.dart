import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_lang.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

class CommunicationDocumentsScreen extends StatefulWidget {
  const CommunicationDocumentsScreen({super.key});

  @override
  State<CommunicationDocumentsScreen> createState() =>
      _CommunicationDocumentsScreenState();
}

class _CommunicationDocumentsScreenState
    extends State<CommunicationDocumentsScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  int _tabIndex = 0;

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _documents = [];

  final _noticeTitle = TextEditingController();
  final _noticeMessage = TextEditingController();
  String _targetRole = '';
  String _targetClassId = '';
  String _priority = 'NORMAL';

  final _docTitle = TextEditingController();
  final _docUrl = TextEditingController();
  final _docEntityType = TextEditingController(text: 'GENERAL');
  final _docEntityId = TextEditingController(text: 'GENERAL');
  final _docNotes = TextEditingController();

  bool get _canWrite =>
      SessionService.role == 'ADMIN' || SessionService.role == 'ACCOUNTANT';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _noticeTitle.dispose();
    _noticeMessage.dispose();
    _docTitle.dispose();
    _docUrl.dispose();
    _docEntityType.dispose();
    _docEntityId.dispose();
    _docNotes.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final responses = await Future.wait([
      _api.get('listClasses'),
      _api.get('listNotices',
          query: {if (_targetClassId.isNotEmpty) 'class_id': _targetClassId}),
      _api.get('listDocuments'),
    ]);
    if (!mounted) return;
    if (responses[0]['ok'] == true) _classes = _rows(responses[0]);
    if (responses[1]['ok'] == true) _notices = _rows(responses[1]);
    if (responses[2]['ok'] == true) _documents = _rows(responses[2]);
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> res) {
    return (res['data'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _publishNotice() async {
    if (_noticeTitle.text.trim().isEmpty ||
        _noticeMessage.text.trim().isEmpty) {
      _snack(AppLang.t(
          'Title ও message প্রয়োজন', 'Title and message are required'));
      return;
    }
    await _post(
        'publishNotice',
        {
          'title': _noticeTitle.text.trim(),
          'message': _noticeMessage.text.trim(),
          'target_role': _targetRole,
          'target_class_id': _targetClassId,
          'priority': _priority,
          'updated_by': SessionService.userId,
        },
        AppLang.t('Notice published', 'Notice published'));
    _noticeTitle.clear();
    _noticeMessage.clear();
  }

  Future<void> _markRead(String noticeId) async {
    await _post('markNoticeRead', {'notice_id': noticeId},
        AppLang.t('Marked read', 'Marked read'),
        requireWrite: false);
  }

  Future<void> _saveDocument() async {
    if (_docTitle.text.trim().isEmpty || _docUrl.text.trim().isEmpty) {
      _snack(AppLang.t('Document title ও URL প্রয়োজন',
          'Document title and URL are required'));
      return;
    }
    await _post(
        'upsertDocument',
        {
          'title': _docTitle.text.trim(),
          'url': _docUrl.text.trim(),
          'entity_type': _docEntityType.text.trim(),
          'entity_id': _docEntityId.text.trim(),
          'notes': _docNotes.text.trim(),
          'updated_by': SessionService.userId,
        },
        AppLang.t('Document saved', 'Document saved'));
    _docTitle.clear();
    _docUrl.clear();
    _docNotes.clear();
  }

  Future<void> _post(String action, Map<String, dynamic> payload, String okMsg,
      {bool requireWrite = true}) async {
    if (requireWrite && !_canWrite) {
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
          ? AppLang.t('Offline saved', 'Offline saved')
          : okMsg);
    } else {
      _snack('${res['message'] ?? res['error'] ?? 'Failed'}');
    }
  }

  Future<void> _openUrl(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        title: AppLang.t('নোটিশ ও ডকুমেন্ট', 'Notices & Documents'),
        actions: [
          IconButton(
              onPressed: _loading ? null : _loadAll,
              icon: const Icon(Icons.refresh))
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
                    _tabs(),
                    const SizedBox(height: 14),
                    _tabIndex == 0 ? _noticePanel() : _documentPanel(),
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
              colors: [Color(0xFF203A43), Color(0xFF2C5364), Color(0xFFB7E4C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: Padding(
        padding: EdgeInsets.all(wide ? 24 : 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              AppLang.t('Targeted Notices & Document Vault',
                  'Targeted Notices & Document Vault'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
              AppLang.t('Role/class/user notice এবং linked document vault।',
                  'Role/class/user notices and linked document vault.'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.88))),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _metric('Notices', _notices.length),
            _metric('Documents', _documents.length)
          ]),
        ]),
      ),
    );
  }

  Widget _metric(String label, dynamic value) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
      child: Text('$label: $value',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700)));

  Widget _tabs() {
    return Row(children: [
      ChoiceChip(
          selected: _tabIndex == 0,
          avatar: const Icon(Icons.campaign, size: 18),
          label: Text(AppLang.t('Notices', 'Notices')),
          onSelected: (_) => setState(() => _tabIndex = 0)),
      const SizedBox(width: 8),
      ChoiceChip(
          selected: _tabIndex == 1,
          avatar: const Icon(Icons.folder, size: 18),
          label: Text(AppLang.t('Documents', 'Documents')),
          onSelected: (_) => setState(() => _tabIndex = 1)),
    ]);
  }

  Widget _panel(String title, Widget child) => Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            child
          ])));

  Widget _noticePanel() {
    return _panel(
        AppLang.t('Publish & Read Notices', 'Publish & Read Notices'),
        Column(children: [
          if (_canWrite) ...[
            TextField(
                controller: _noticeTitle,
                decoration:
                    InputDecoration(labelText: AppLang.t('Title', 'Title'))),
            TextField(
                controller: _noticeMessage,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: AppLang.t('Message', 'Message'))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _roleDropdown()),
              const SizedBox(width: 8),
              Expanded(child: _classDropdown())
            ]),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
                initialValue: _priority,
                items: ['NORMAL', 'HIGH', 'URGENT']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v ?? 'NORMAL'),
                decoration: InputDecoration(
                    labelText: AppLang.t('Priority', 'Priority'))),
            const SizedBox(height: 10),
            Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                    onPressed: _saving ? null : _publishNotice,
                    icon: const Icon(Icons.send),
                    label: Text(AppLang.t('Publish', 'Publish')))),
            const Divider(height: 24),
          ],
          ..._notices.map((n) => Card(
              elevation: 0,
              child: ListTile(
                  title: Text(n['title']?.toString() ?? '-'),
                  subtitle: Text(
                      '${n['message'] ?? ''}\n${n['target_role'] ?? ''} ${n['target_class_id'] ?? ''}'),
                  trailing: n['read'] == true
                      ? const Icon(Icons.done_all)
                      : IconButton(
                          icon: const Icon(Icons.mark_email_read),
                          onPressed: () => _markRead(n['id'].toString()))))),
        ]));
  }

  Widget _roleDropdown() {
    return DropdownButtonFormField<String>(
        initialValue: _targetRole,
        items: ['', 'ADMIN', 'ACCOUNTANT', 'FIELD_USER', 'VIEWER']
            .map((r) => DropdownMenuItem(
                value: r,
                child: Text(r.isEmpty ? AppLang.t('সব role', 'All roles') : r)))
            .toList(),
        onChanged: (v) => setState(() => _targetRole = v ?? ''),
        decoration: InputDecoration(
            labelText: AppLang.t('Target role', 'Target role')));
  }

  Widget _classDropdown() {
    return DropdownButtonFormField<String>(
        initialValue: _classes.any((c) => c['id'].toString() == _targetClassId)
            ? _targetClassId
            : '',
        items: [
          DropdownMenuItem(
              value: '', child: Text(AppLang.t('সব শ্রেণি', 'All classes'))),
          ..._classes.map((c) => DropdownMenuItem(
              value: c['id'].toString(),
              child: Text(c['name']?.toString() ?? '-')))
        ],
        onChanged: (v) => setState(() => _targetClassId = v ?? ''),
        decoration: InputDecoration(
            labelText: AppLang.t('Target class', 'Target class')));
  }

  Widget _documentPanel() {
    return _panel(
        AppLang.t('Document Vault', 'Document Vault'),
        Column(children: [
          if (_canWrite) ...[
            TextField(
                controller: _docTitle,
                decoration:
                    InputDecoration(labelText: AppLang.t('Title', 'Title'))),
            TextField(
                controller: _docUrl,
                decoration:
                    InputDecoration(labelText: AppLang.t('URL', 'URL'))),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _docEntityType,
                      decoration: InputDecoration(
                          labelText: AppLang.t('Entity type', 'Entity type')))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _docEntityId,
                      decoration: InputDecoration(
                          labelText: AppLang.t('Entity ID', 'Entity ID'))))
            ]),
            TextField(
                controller: _docNotes,
                decoration:
                    InputDecoration(labelText: AppLang.t('Notes', 'Notes'))),
            const SizedBox(height: 10),
            Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                    onPressed: _saving ? null : _saveDocument,
                    icon: const Icon(Icons.save),
                    label: Text(AppLang.t('Save Document', 'Save Document')))),
            const Divider(height: 24),
          ],
          ..._documents.map((d) => Card(
              elevation: 0,
              child: ListTile(
                  title: Text(d['title']?.toString() ?? '-'),
                  subtitle: Text(
                      '${d['entity_type'] ?? ''}: ${d['entity_id'] ?? ''}\n${d['url'] ?? ''}'),
                  trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openUrl(d['url']?.toString() ?? ''))))),
        ]));
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_config.dart';
import '../../shared/models/dashboard_summary.dart';
import '../../shared/models/notification_settings.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/local_store_service.dart';
import '../../shared/services/pwa_runtime_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/themed_date_picker.dart';
import 'fund_detail_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  static final Uri _apkDownloadUri = Uri.parse(
    AppConfig.apkDownloadUrl,
  );
  bool _loading = true;
  bool _offline = false;
  String? _error;
  DashboardSummary? _summary;
  NotificationSettings _notificationSettings = NotificationSettings.defaults();
  List<Map<String, dynamic>> _recentNotifications = [];
  bool _loadingPremium = true;
  bool _loadingMonthly = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _firstDataMonth;
  List<Map<String, dynamic>> _monthlyRows = [];
  double _monthlyIn = 0;
  double _monthlyOut = 0;
  double _monthlyBalance = 0;
  bool _isStandalonePwa = true;
  bool _canInstallPwa = false;
  bool _webOnline = true;
  String _summaryFrom = '';
  String _summaryTo = '';
  DateTime? _lastBackPressedAt;

  @override
  void initState() {
    super.initState();
    _syncPwaState();
    pwaRuntimeService.standaloneMode.addListener(_syncPwaState);
    pwaRuntimeService.installAvailable.addListener(_syncPwaState);
    pwaRuntimeService.onlineStatus.addListener(_syncPwaState);
    _load();
  }

  @override
  void dispose() {
    pwaRuntimeService.standaloneMode.removeListener(_syncPwaState);
    pwaRuntimeService.installAvailable.removeListener(_syncPwaState);
    pwaRuntimeService.onlineStatus.removeListener(_syncPwaState);
    super.dispose();
  }

  void _syncPwaState() {
    if (!mounted) return;
    setState(() {
      _isStandalonePwa = pwaRuntimeService.standaloneMode.value;
      _canInstallPwa = pwaRuntimeService.installAvailable.value;
      _webOnline = pwaRuntimeService.onlineStatus.value;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });
    try {
      final now = DateTime.now();
      final todayKey = _dateKey(now);
      String fromKey = '2022-01-26';
      String toKey = todayKey;

      try {
        final uiRes = await _api.get('getAppUiSettings');
        if (uiRes['ok'] == true) {
          final ui = Map<String, dynamic>.from(uiRes['data'] as Map? ?? {});
          final fromParsed = _parseIsoDate(ui['default_from_date']);
          final toParsed = _parseIsoDate(ui['default_to_date']);
          final toSource =
              (ui['default_to_source'] ?? 'TODAY').toString().toUpperCase();

          if (fromParsed != null) fromKey = _dateKey(fromParsed);
          if (toSource == 'TODAY') {
            toKey = todayKey;
          } else if (toParsed != null) {
            final capped = toParsed.isAfter(now) ? now : toParsed;
            toKey = _dateKey(capped);
          }
          _offline = _offline || (uiRes['offline'] == true);
        }
      } catch (_) {
        // Fallback to built-in defaults.
      }

      try {
        final statsRes = await _api.get('datasetStats');
        if (statsRes['ok'] == true) {
          final stats =
              Map<String, dynamic>.from(statsRes['data'] as Map? ?? {});
          final firstDate = _parseIsoDate(stats['first_txn_date']);
          final lastDate = _parseIsoDate(stats['last_txn_date']);
          if (firstDate != null) {
            _firstDataMonth = DateTime(firstDate.year, firstDate.month);
          }
          if (lastDate != null) {
            final cappedLast = lastDate.isAfter(now) ? now : lastDate;
            _selectedMonth = DateTime(cappedLast.year, cappedLast.month);
          }
          _offline = _offline || (statsRes['offline'] == true);
        }
      } catch (_) {
        // Keep dashboard usable even if dataset stats is unavailable.
      }

      final res = await _api.get(
        'dashboardSummary',
        query: {
          'from': fromKey,
          'to': toKey,
        },
      );
      if (res['ok'] == true) {
        _summary = DashboardSummary.fromMap(
            (res['data'] ?? {}) as Map<String, dynamic>);
        _summaryFrom = fromKey;
        _summaryTo = toKey;
        _offline = _offline || (res['offline'] == true);
        await Future.wait([
          _loadPremiumData(),
          _loadMonthlyData(autoBacktrack: true),
        ]);
      } else {
        _error =
            (res['message'] ?? res['error'] ?? 'তথ্য লোড ব্যর্থ').toString();
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPremiumData() async {
    setState(() => _loadingPremium = true);
    try {
      final result = await Future.wait([
        _api.get('getNotificationSettings'),
        _api.get('listInAppNotifications'),
      ]);
      final settingsRes = result[0];
      final eventsRes = result[1];

      if (settingsRes['ok'] == true) {
        _notificationSettings = NotificationSettings.fromApi(
          Map<String, dynamic>.from(settingsRes['data'] as Map? ?? {}),
        );
      }

      if (eventsRes['ok'] == true) {
        _recentNotifications = (eventsRes['data'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
            .take(6)
            .toList();
      }
    } catch (_) {
      // Keep dashboard resilient even if premium widgets fail.
    } finally {
      if (mounted) {
        setState(() => _loadingPremium = false);
      }
    }
  }

  String _monthKey(DateTime month) {
    return '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseIsoDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return null;
    return DateTime.tryParse(raw);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final cleaned =
        (value ?? '').toString().replaceAll(',', '').replaceAll('৳', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  Future<void> _loadMonthlyData({bool autoBacktrack = false}) async {
    setState(() => _loadingMonthly = true);
    try {
      DateTime cursor = _selectedMonth;
      Map<String, dynamic> selectedData = {};
      List<Map<String, dynamic>> selectedRows = [];

      for (int attempt = 0; attempt < 60; attempt++) {
        final res = await _api.get(
          'monthlyReport',
          query: {'monthKey': _monthKey(cursor)},
        );
        if (res['ok'] != true) break;

        final data = Map<String, dynamic>.from(res['data'] as Map? ?? {});
        final rows = (data['rows'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        selectedData = data;
        selectedRows = rows;
        _offline = _offline || (res['offline'] == true);

        if (!autoBacktrack || rows.isNotEmpty) {
          _selectedMonth = DateTime(cursor.year, cursor.month);
          break;
        }

        final previous = DateTime(cursor.year, cursor.month - 1);
        final reachedFloor = _firstDataMonth != null &&
            previous.isBefore(
                DateTime(_firstDataMonth!.year, _firstDataMonth!.month));
        if (reachedFloor) {
          _selectedMonth = DateTime(cursor.year, cursor.month);
          break;
        }
        cursor = previous;
      }

      _monthlyIn = _toDouble(selectedData['totalIn']);
      _monthlyOut = _toDouble(selectedData['totalOut']);
      _monthlyBalance = _toDouble(selectedData['balance']);
      _monthlyRows = selectedRows;
      if (selectedRows.isNotEmpty) {
        _monthlyRows.sort((a, b) => (b['txn_date'] ?? '')
            .toString()
            .compareTo((a['txn_date'] ?? '').toString()));
      }
    } catch (_) {
      // Keep dashboard resilient on monthly widget failure.
    } finally {
      if (mounted) {
        setState(() => _loadingMonthly = false);
      }
    }
  }

  Future<void> _shiftMonth(int delta) async {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    setState(() => _selectedMonth = DateTime(next.year, next.month));
    await _loadMonthlyData();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressedAt == null ||
        now.difference(_lastBackPressedAt!) > const Duration(seconds: 2)) {
      _lastBackPressedAt = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('বের হতে আবার চাপুন')),
      );
      return false;
    }
    return true;
  }

  String _fmt(double n) {
    if (n >= 10000000) return '৳${(n / 10000000).toStringAsFixed(1)}কোটি';
    if (n >= 100000) return '৳${(n / 100000).toStringAsFixed(1)}লাখ';
    return '৳${NumberFormat('#,##0', 'en_US').format(n.toInt())}';
  }

  void _goToFund(String fundKey, String fundName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FundDetailPage(fundKey: fundKey, fundName: fundName),
      ),
    );
  }

  Future<void> _downloadApk() async {
    final opened = await launchUrl(
      _apkDownloadUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('APK download link খোলা যায়নি')),
      );
    }
  }

  Future<void> _installWebApp() async {
    final opened = await pwaRuntimeService.promptInstall();
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pwaRuntimeService.installHelpMessage(isEnglish: false),
        ),
      ),
    );
  }

  Future<void> _quickEntry({required bool income}) async {
    final formKey = GlobalKey<FormState>();
    final dateCtrl = TextEditingController(
        text: DateTime.now().toIso8601String().split('T').first);
    final amountCtrl = TextEditingController();
    final sourceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var fundType = 'CONSTRUCTION';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(income ? '+ দান / আয়' : '+ ব্যয়'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'তারিখ (YYYY-MM-DD)',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () async {
                          final initial =
                              _parseIsoDate(dateCtrl.text) ?? DateTime.now();
                          final picked = await showThemedDatePicker(
                            context: ctx,
                            initialDate: initial,
                            firstDate: DateTime(2000, 1, 1),
                            lastDate: DateTime(2100, 12, 31),
                          );
                          if (picked == null) return;
                          final normalized =
                              '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          setD(() => dateCtrl.text = normalized);
                        },
                      ),
                    ),
                    onTap: () async {
                      final initial =
                          _parseIsoDate(dateCtrl.text) ?? DateTime.now();
                      final picked = await showThemedDatePicker(
                        context: ctx,
                        initialDate: initial,
                        firstDate: DateTime(2000, 1, 1),
                        lastDate: DateTime(2100, 12, 31),
                      );
                      if (picked == null) return;
                      final normalized =
                          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      setD(() => dateCtrl.text = normalized);
                    },
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'দিন' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: fundType,
                    decoration: const InputDecoration(labelText: 'ফান্ড'),
                    items: const [
                      DropdownMenuItem(
                          value: 'CONSTRUCTION', child: Text('নির্মাণ ফান্ড')),
                      DropdownMenuItem(
                          value: 'JAKAT', child: Text('যাকাত ফান্ড')),
                      DropdownMenuItem(
                          value: 'SCHOLARSHIP', child: Text('বৃত্তি ফান্ড')),
                      DropdownMenuItem(
                          value: 'GENERAL', child: Text('সাদাকাহ / সাধারণ')),
                    ],
                    onChanged: (v) =>
                        setD(() => fundType = v ?? 'CONSTRUCTION'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'পরিমাণ (৳)'),
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '') ?? 0;
                      return n <= 0 ? 'সঠিক পরিমাণ দিন' : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: sourceCtrl,
                    decoration: InputDecoration(
                        labelText: income ? 'দাতার নাম' : 'কোথায় খরচ'),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'দিন' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: noteCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'নোট (ঐচ্ছিক)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final res = await _api.post('createTransaction', {
      'user_role': SessionService.role,
      'payload': {
        'txn_date': dateCtrl.text.trim(),
        'direction': income ? 'IN' : 'OUT',
        'fund_type': fundType,
        'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
        'source_or_vendor': sourceCtrl.text.trim(),
        'category': income ? 'DONATION' : 'EXPENSE',
        'notes': noteCtrl.text.trim(),
        'created_by': SessionService.userId,
      },
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ??
            (res['ok'] == true ? 'সংরক্ষিত হয়েছে' : 'ব্যর্থ হয়েছে')),
        backgroundColor: res['ok'] == true ? Colors.green : Colors.red,
      ),
    );
    if (res['ok'] == true && res['queued'] != true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (SessionService.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          title: const Text('মাদ্রাসা ERP',
              style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            if (_offline)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.cloud_off, size: 18),
              ),
            IconButton(
              onPressed: _load,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh),
              tooltip: 'রিফ্রেশ',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              onSelected: (v) {
                switch (v) {
                  case 'salary':
                    Navigator.pushNamed(context, '/salary');
                  case 'scholarship':
                    Navigator.pushNamed(context, '/scholarship');
                  case 'beneficiaries':
                    Navigator.pushNamed(context, '/beneficiaries');
                  case 'reports':
                    Navigator.pushNamed(context, '/reports');
                  case 'settings':
                    Navigator.pushNamed(context, '/settings');
                  case 'logout':
                    SessionService.clear();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (_) => false);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'salary', child: Text('বেতন')),
                const PopupMenuItem(
                    value: 'scholarship', child: Text('বৃত্তি')),
                const PopupMenuItem(
                    value: 'beneficiaries', child: Text('উপকারভোগী')),
                const PopupMenuItem(value: 'reports', child: Text('রিপোর্ট')),
                if (SessionService.role == 'ADMIN')
                  const PopupMenuItem(value: 'settings', child: Text('সেটিংস')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'logout', child: Text('লগআউট')),
              ],
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : _buildBody(),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'expense',
              onPressed: () => _quickEntry(income: false),
              backgroundColor: Colors.red.shade600,
              tooltip: 'ব্যয় যোগ করুন',
              child: const Icon(Icons.remove, color: Colors.white),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'income',
              onPressed: () => _quickEntry(income: true),
              tooltip: 'দান / আয় যোগ করুন',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final s = _summary;
    if (s == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('কোনো তথ্য নেই'),
            const SizedBox(height: 12),
            OutlinedButton(
                onPressed: _load, child: const Text('পুনরায় চেষ্টা করুন')),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 1100;
        final isTablet = width >= 760;
        final fundCardWidth = isWide ? 290.0 : (isTablet ? 260.0 : 180.0);
        final maxWidth = isWide ? 1320.0 : 840.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  isWide ? 24 : 16, 16, isWide ? 24 : 16, 100),
              children: [
                // Greeting
                _GreetingCard(),
                const SizedBox(height: 12),

                // Total Found — big summary card
                _TotalSummaryCard(summary: s, fmt: _fmt),
                if (_summaryFrom.isNotEmpty || _summaryTo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 10),
                    child: Text(
                      'ডিফল্ট রেঞ্জ: ${_summaryFrom.isEmpty ? 'শুরু' : _summaryFrom} থেকে ${_summaryTo.isEmpty ? 'আজ' : _summaryTo}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),

                _QuickActionsRow(
                  onAddIncome: () => _quickEntry(income: true),
                  onAddExpense: () => _quickEntry(income: false),
                  onOpenReports: () => Navigator.pushNamed(context, '/reports'),
                  onDownloadApk: _downloadApk,
                  onInstallPwa: (!_isStandalonePwa && _canInstallPwa)
                      ? _installWebApp
                      : null,
                  onOpenSettings: SessionService.role == 'ADMIN'
                      ? () => Navigator.pushNamed(context, '/settings')
                      : null,
                ),
                const SizedBox(height: 14),
                _PwaModeCard(
                  isStandalonePwa: _isStandalonePwa,
                  canInstallPwa: _canInstallPwa,
                  isOnline: _webOnline,
                  onInstallPwa: (!_isStandalonePwa && _canInstallPwa)
                      ? _installWebApp
                      : null,
                  installHelpText:
                      pwaRuntimeService.installHelpMessage(isEnglish: false),
                ),
                const SizedBox(height: 14),
                _ControlBarCard(
                  selectedMonth: _selectedMonth,
                  loadingMonthly: _loadingMonthly,
                  monthlyIn: _monthlyIn,
                  monthlyOut: _monthlyOut,
                  monthlyBalance: _monthlyBalance,
                  fmt: _fmt,
                  onPrevMonth: () => _shiftMonth(-1),
                  onNextMonth: () => _shiftMonth(1),
                ),
                const SizedBox(height: 14),

                // Fund cards
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('ফান্ড অনুযায়ী বিবরণ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: fundCardWidth,
                      child: _FundCard(
                        name: 'নির্মাণ ফান্ড',
                        icon: Icons.construction,
                        color: const Color(0xFF1D4ED8),
                        fund: s.fund('CONSTRUCTION'),
                        fmt: _fmt,
                        onTap: () => _goToFund('CONSTRUCTION', 'নির্মাণ ফান্ড'),
                      ),
                    ),
                    SizedBox(
                      width: fundCardWidth,
                      child: _FundCard(
                        name: 'যাকাত ফান্ড',
                        icon: Icons.volunteer_activism,
                        color: const Color(0xFF15803D),
                        fund: s.fund('JAKAT'),
                        fmt: _fmt,
                        onTap: () => _goToFund('JAKAT', 'যাকাত ফান্ড'),
                      ),
                    ),
                    SizedBox(
                      width: fundCardWidth,
                      child: _FundCard(
                        name: 'বৃত্তি ফান্ড',
                        icon: Icons.school,
                        color: const Color(0xFF7C3AED),
                        fund: s.fund('SCHOLARSHIP'),
                        fmt: _fmt,
                        onTap: () => _goToFund('SCHOLARSHIP', 'বৃত্তি ফান্ড'),
                      ),
                    ),
                    SizedBox(
                      width: fundCardWidth,
                      child: _FundCard(
                        name: 'সাদাকাহ / সাধারণ',
                        icon: Icons.favorite,
                        color: const Color(0xFFB45309),
                        fund: s.fund('GENERAL'),
                        fmt: _fmt,
                        onTap: () => _goToFund('GENERAL', 'সাদাকাহ / সাধারণ'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Separation calculation section
                _SeparationCard(summary: s, fmt: _fmt, onTap: _goToFund),
                const SizedBox(height: 16),
                _RecentTransactionsCard(
                  rows: _monthlyRows,
                  loading: _loadingMonthly,
                  fmt: _fmt,
                ),
                const SizedBox(height: 16),
                _PremiumStatusCard(
                  loading: _loadingPremium,
                  settings: _notificationSettings,
                  recentEvents: _recentNotifications,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Greeting Card ──────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (SessionService.userName.isNotEmpty
                    ? SessionService.userName[0].toUpperCase()
                    : 'A'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('আস-সালামু আলাইকুম, ${SessionService.userName}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('ভূমিকা: ${_roleLabel(SessionService.role)}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'ADMIN':
        return 'অ্যাডমিন';
      case 'ACCOUNTANT':
        return 'হিসাবরক্ষক';
      case 'FIELD_USER':
        return 'ফিল্ড ব্যবহারকারী';
      default:
        return 'দর্শক';
    }
  }
}

// ─── Total Summary Card ──────────────────────────────────────────────────────

class _TotalSummaryCard extends StatelessWidget {
  final DashboardSummary summary;
  final String Function(double) fmt;

  const _TotalSummaryCard({required this.summary, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final teal = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 2,
      color: teal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('মোট সংগ্রহ',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              fmt(summary.totalIn),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SummaryChip(
                  icon: Icons.arrow_upward,
                  label: 'মোট আয়',
                  value: fmt(summary.totalIn),
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  icon: Icons.arrow_downward,
                  label: 'মোট ব্যয়',
                  value: fmt(summary.totalOut),
                  color: Colors.redAccent.shade100,
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  icon: Icons.account_balance_wallet,
                  label: 'ব্যালেন্স',
                  value: fmt(summary.balance),
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ]),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

// ─── Fund Card ───────────────────────────────────────────────────────────────

class _FundCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final FundSummary fund;
  final String Function(double) fmt;
  final VoidCallback onTap;

  const _FundCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.fund,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: color.withValues(alpha: 0.5), size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text('সংগ্রহ',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            Text(fmt(fund.incoming),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ব্যয়',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500)),
                    Text(fmt(fund.outgoing),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ব্যালেন্স',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500)),
                    Text(
                      fmt(fund.balance),
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              fund.balance >= 0 ? color : Colors.red.shade700,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Separation Calculation Card ─────────────────────────────────────────────

class _SeparationCard extends StatelessWidget {
  final DashboardSummary summary;
  final String Function(double) fmt;
  final void Function(String, String) onTap;

  const _SeparationCard(
      {required this.summary, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final zakatIn = summary.fund('JAKAT').incoming;
    final scholarshipIn = summary.fund('SCHOLARSHIP').incoming;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calculate_outlined,
                    size: 18, color: Color(0xFF0F766E)),
                SizedBox(width: 8),
                Text('ফান্ড পৃথকীকরণ হিসাব',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const Divider(height: 20),
            _SepRow(
              label: 'মোট সংগ্রহ',
              value: fmt(summary.totalIn),
              isTotal: true,
            ),
            _SepRow(
              label: '(−) যাকাত',
              value: '−${fmt(zakatIn)}',
              sublabel: 'আলাদা ফান্ড',
              color: Colors.green.shade700,
              onTap: () => onTap('JAKAT', 'যাকাত ফান্ড'),
            ),
            _SepRow(
              label: 'যাকাত বাদে মোট',
              value: fmt(summary.balanceExclZakat),
              isSubtotal: true,
              onTap: () => onTap('CONSTRUCTION', 'নির্মাণ ফান্ড'),
            ),
            _SepRow(
              label: '(−) বৃত্তি',
              value: '−${fmt(scholarshipIn)}',
              sublabel: 'আলাদা ফান্ড',
              color: Colors.purple.shade700,
              onTap: () => onTap('SCHOLARSHIP', 'বৃত্তি ফান্ড'),
            ),
            _SepRow(
              label: 'যাকাত ও বৃত্তি বাদে',
              value: fmt(summary.balanceExclZakatScholarship),
              isSubtotal: true,
              isLast: true,
            ),
            const SizedBox(height: 4),
            Text(
              '← ডান দিকের তীর চিহ্নে চাপলে বিস্তারিত দেখতে পারবেন',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _SepRow extends StatelessWidget {
  final String label;
  final String value;
  final String? sublabel;
  final Color? color;
  final bool isTotal;
  final bool isSubtotal;
  final bool isLast;
  final VoidCallback? onTap;

  const _SepRow({
    required this.label,
    required this.value,
    this.sublabel,
    this.color,
    this.isTotal = false,
    this.isSubtotal = false,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: isTotal ? 14 : 13,
      fontWeight: isTotal || isSubtotal ? FontWeight.bold : FontWeight.normal,
      color: color ?? (isTotal ? Colors.black87 : Colors.grey.shade800),
    );
    final valueStyle = TextStyle(
      fontSize: isTotal ? 15 : 13,
      fontWeight: FontWeight.bold,
      color: color ?? (isSubtotal ? const Color(0xFF0F766E) : Colors.black87),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                if (sublabel != null)
                  Text(sublabel!,
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(value, style: valueStyle),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onTap,
              child: Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }
}

class _PwaModeCard extends StatelessWidget {
  final bool isStandalonePwa;
  final bool canInstallPwa;
  final bool isOnline;
  final VoidCallback? onInstallPwa;
  final String installHelpText;

  const _PwaModeCard({
    required this.isStandalonePwa,
    required this.canInstallPwa,
    required this.isOnline,
    required this.onInstallPwa,
    required this.installHelpText,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isStandalonePwa ? const Color(0xFF99F6E4) : const Color(0xFFBFDBFE);
    final bgColor =
        isStandalonePwa ? const Color(0xFFF0FDFA) : const Color(0xFFEFF6FF);
    final iconColor =
        isStandalonePwa ? const Color(0xFF0F766E) : const Color(0xFF1D4ED8);

    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isStandalonePwa
                      ? Icons.phone_android_rounded
                      : Icons.language_rounded,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isStandalonePwa
                        ? 'Native-like mode active'
                        : 'Browser mode detected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusDot(
                  color:
                      isOnline ? Colors.green.shade600 : Colors.orange.shade700,
                  label: isOnline ? 'Online' : 'Offline',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isStandalonePwa
                  ? 'URL bar ছাড়া app-mode এ চলছে।'
                  : 'Real app feel পেতে Install Web App ব্যবহার করুন।',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (!isStandalonePwa) ...[
              const SizedBox(height: 10),
              if (onInstallPwa != null)
                FilledButton.icon(
                  onPressed: onInstallPwa,
                  icon: const Icon(Icons.install_mobile),
                  label: const Text('Install Web App'),
                ),
              if (onInstallPwa == null || !canInstallPwa)
                Text(
                  installHelpText,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}

// ─── Error View ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('পুনরায় চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onOpenReports;
  final VoidCallback onDownloadApk;
  final VoidCallback? onInstallPwa;
  final VoidCallback? onOpenSettings;

  const _QuickActionsRow({
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onOpenReports,
    required this.onDownloadApk,
    this.onInstallPwa,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ActionChip(
              avatar: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('দ্রুত আয় যোগ'),
              onPressed: onAddIncome,
            ),
            ActionChip(
              avatar: const Icon(Icons.remove_circle_outline, size: 18),
              label: const Text('দ্রুত ব্যয় যোগ'),
              onPressed: onAddExpense,
            ),
            ActionChip(
              avatar: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text('রিপোর্ট'),
              onPressed: onOpenReports,
            ),
            ActionChip(
              avatar: const Icon(Icons.download_for_offline_outlined, size: 18),
              label: const Text('APK ডাউনলোড'),
              onPressed: onDownloadApk,
            ),
            if (onInstallPwa != null)
              ActionChip(
                avatar: const Icon(Icons.install_mobile, size: 18),
                label: const Text('Install Web App'),
                onPressed: onInstallPwa,
              ),
            if (onOpenSettings != null)
              ActionChip(
                avatar: const Icon(Icons.tune, size: 18),
                label: const Text('অ্যাডমিন কন্ট্রোল'),
                onPressed: onOpenSettings,
              ),
          ],
        ),
      ),
    );
  }
}

class _ControlBarCard extends StatelessWidget {
  final DateTime selectedMonth;
  final bool loadingMonthly;
  final double monthlyIn;
  final double monthlyOut;
  final double monthlyBalance;
  final String Function(double) fmt;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _ControlBarCard({
    required this.selectedMonth,
    required this.loadingMonthly,
    required this.monthlyIn,
    required this.monthlyOut,
    required this.monthlyBalance,
    required this.fmt,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'en_US').format(selectedMonth);

    return Card(
      elevation: 0,
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month,
                    color: Color(0xFF1D4ED8), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'মাসিক কন্ট্রোল ও সারাংশ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onPrevMonth,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous month',
                ),
                Text(monthLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next month',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (loadingMonthly)
              const LinearProgressIndicator(minHeight: 3)
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MiniStat(
                    title: 'মাসিক আয়',
                    value: fmt(monthlyIn),
                    icon: Icons.trending_up,
                    color: const Color(0xFF166534),
                  ),
                  _MiniStat(
                    title: 'মাসিক ব্যয়',
                    value: fmt(monthlyOut),
                    icon: Icons.trending_down,
                    color: const Color(0xFFB91C1C),
                  ),
                  _MiniStat(
                    title: 'মাসিক ব্যালেন্স',
                    value: fmt(monthlyBalance),
                    icon: Icons.savings_outlined,
                    color: monthlyBalance >= 0
                        ? const Color(0xFF0F766E)
                        : const Color(0xFFB91C1C),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final bool loading;
  final String Function(double) fmt;

  const _RecentTransactionsCard({
    required this.rows,
    required this.loading,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 18, color: Color(0xFF0F766E)),
                SizedBox(width: 8),
                Text('সাম্প্রতিক লেনদেন (মাসিক)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (rows.isEmpty)
              Text(
                'এই মাসে কোনো transaction data পাওয়া যায়নি।',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  headingRowHeight: 36,
                  dataRowMinHeight: 34,
                  dataRowMaxHeight: 44,
                  columns: const [
                    DataColumn(label: Text('তারিখ')),
                    DataColumn(label: Text('ধরণ')),
                    DataColumn(label: Text('ফান্ড')),
                    DataColumn(label: Text('পরিমাণ')),
                    DataColumn(label: Text('উৎস/ভেন্ডর')),
                  ],
                  rows: rows.take(12).map((row) {
                    final direction = (row['direction'] ?? '').toString();
                    final amount = ((row['amount'] ?? 0) as num).toDouble();
                    final color = direction == 'IN'
                        ? const Color(0xFF166534)
                        : const Color(0xFFB91C1C);
                    return DataRow(cells: [
                      DataCell(Text((row['txn_date'] ?? '').toString())),
                      DataCell(Text(direction)),
                      DataCell(Text((row['fund_type'] ?? '').toString())),
                      DataCell(Text(
                        fmt(amount),
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: color),
                      )),
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            (row['source_or_vendor'] ?? '').toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumStatusCard extends StatelessWidget {
  final bool loading;
  final NotificationSettings settings;
  final List<Map<String, dynamic>> recentEvents;

  const _PremiumStatusCard({
    required this.loading,
    required this.settings,
    required this.recentEvents,
  });

  int get _emailToggleOnCount {
    var count = 0;
    if (settings.emailApproval) count++;
    if (settings.emailFailedSync) count++;
    if (settings.emailDailySummary) count++;
    if (settings.emailDueReminder) count++;
    if (settings.emailSecurityAlert) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.workspace_premium_outlined,
                    size: 18, color: Color(0xFF0F766E)),
                SizedBox(width: 8),
                Text(
                  'প্রিমিয়াম স্ট্যাটাস',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MiniStat(
                    title: 'In-app Alerts',
                    value: settings.inAppEnabled ? 'ON' : 'OFF',
                    icon: Icons.notifications_active_outlined,
                    color: settings.inAppEnabled
                        ? const Color(0xFF166534)
                        : Colors.grey,
                  ),
                  _MiniStat(
                    title: 'Email Toggles',
                    value: '$_emailToggleOnCount / 5 ON',
                    icon: Icons.email_outlined,
                    color: _emailToggleOnCount > 0
                        ? const Color(0xFF0F766E)
                        : Colors.grey,
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: LocalStoreService.pendingCount,
                    builder: (_, pending, __) => _MiniStat(
                      title: 'Pending Sync',
                      value: '$pending',
                      icon: Icons.sync_problem,
                      color: pending > 0
                          ? const Color(0xFFB45309)
                          : const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('সাম্প্রতিক নোটিফিকেশন',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              if (recentEvents.isEmpty)
                Text(
                  'এখনো কোনো notification event নেই',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                )
              else
                ...recentEvents.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.fiber_manual_record,
                            size: 8, color: Color(0xFF0F766E)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${(e['title'] ?? '').toString()} • ${(e['category'] ?? '').toString()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 11, color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

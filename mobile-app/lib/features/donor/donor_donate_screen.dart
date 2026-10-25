import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../shared/constants/fund_types.dart';
import 'donor_api.dart';
import 'donor_session.dart';

class DonorDonateScreen extends StatefulWidget {
  const DonorDonateScreen({super.key});

  @override
  State<DonorDonateScreen> createState() => _DonorDonateScreenState();
}

class _DonorDonateScreenState extends State<DonorDonateScreen> {
  final _amountBdt = TextEditingController();
  final _amountForeign = TextEditingController();
  final _rate = TextEditingController();
  final _ref = TextEditingController();
  final _notes = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _fundType = 'SADAQAH';
  String _currency = 'BDT';
  String _method = 'CASH';
  bool _loading = false;
  String? _error;

  static const _currencies = ['BDT', 'USD', 'GBP', 'EUR', 'SAR', 'AED', 'MYR', 'QAR', 'KWD', 'OMR'];
  static const _methods = ['CASH', 'BANK_TRANSFER', 'MOBILE_BANKING', 'CHEQUE', 'OTHER'];
  static const _methodLabels = {
    'CASH': 'নগদ', 'BANK_TRANSFER': 'ব্যাংক ট্রান্সফার',
    'MOBILE_BANKING': 'মোবাইল ব্যাংকিং (bKash/Nagad)', 'CHEQUE': 'চেক', 'OTHER': 'অন্যান্য',
  };

  bool get _isForeign => _currency != 'BDT';

  void _recalcBdt() {
    if (!_isForeign) return;
    final foreign = double.tryParse(_amountForeign.text) ?? 0;
    final rate = double.tryParse(_rate.text) ?? 0;
    if (foreign > 0 && rate > 0) {
      _amountBdt.text = (foreign * rate).toStringAsFixed(2);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      final payload = {
        'fund_type': _fundType,
        'amount_bdt': double.tryParse(_amountBdt.text) ?? 0,
        'amount_foreign': _isForeign ? (double.tryParse(_amountForeign.text) ?? 0) : 0,
        'currency': _currency,
        'exchange_rate': _isForeign ? (double.tryParse(_rate.text) ?? 1) : 1,
        'payment_method': _method,
        'txn_reference': _ref.text.trim(),
        'notes': _notes.text.trim(),
      };
      final res = await DonorApi.donate(
        DonorSession.donorId!,
        DonorSession.donorToken!,
        payload,
      );
      if (!mounted) return;
      if (res['ok'] == true) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: Text(AppLang.t('জাযাকাল্লাহু খাইরান!', 'JazakAllahu Khayran!')),
            content: Text(AppLang.t(
              'আপনার দানের তথ্য নিবন্ধিত হয়েছে। অ্যাডমিন নিশ্চিত করলে আপনার ড্যাশবোর্ডে দেখা যাবে।',
              'Your donation is registered. It will appear in your dashboard once confirmed.',
            )),
            actions: [
              TextButton(
                onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pop(); },
                child: Text(AppLang.t('ঠিক আছে', 'OK')),
              ),
            ],
          ),
        );
      } else {
        setState(() => _error = res['message'] as String? ?? AppLang.t('ত্রুটি হয়েছে', 'Error'));
      }
    } catch (e) {
      setState(() => _error = AppLang.t('সংযোগ ত্রুটি', 'Connection error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _amountBdt.dispose(); _amountForeign.dispose(); _rate.dispose();
    _ref.dispose(); _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final funds = FundTypes.donorVisible;
    return Scaffold(
      appBar: AppBar(title: Text(AppLang.t('দান নিবন্ধন', 'Register Donation'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fund type
              DropdownButtonFormField<String>(
                initialValue: _fundType,
                decoration: InputDecoration(
                  labelText: AppLang.t('খাত নির্বাচন করুন', 'Select Fund/Khat'),
                  border: const OutlineInputBorder(),
                ),
                items: funds.map((f) => DropdownMenuItem(
                  value: f.key,
                  child: Text(AppLang.isEnglish.value ? f.labelEn : f.labelBn),
                )).toList(),
                onChanged: (v) => setState(() => _fundType = v ?? 'SADAQAH'),
              ),
              const SizedBox(height: 12),

              // Currency
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: InputDecoration(
                  labelText: AppLang.t('মুদ্রা', 'Currency'),
                  border: const OutlineInputBorder(),
                ),
                items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() { _currency = v ?? 'BDT'; _amountForeign.clear(); _rate.clear(); }),
              ),
              const SizedBox(height: 12),

              if (_isForeign) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountForeign,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLang.t('পরিমাণ ($_currency)', 'Amount ($_currency)'),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => _recalcBdt(),
                        validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                            ? AppLang.t('পরিমাণ দিন', 'Enter amount') : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _rate,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLang.t('রেট (BDT-তে)', 'Rate in BDT'),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => _recalcBdt(),
                        validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                            ? AppLang.t('রেট দিন', 'Enter rate') : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // BDT amount
              TextFormField(
                controller: _amountBdt,
                keyboardType: TextInputType.number,
                readOnly: _isForeign,
                decoration: InputDecoration(
                  labelText: AppLang.t('পরিমাণ (টাকা) *', 'Amount (BDT) *'),
                  prefixText: '৳ ',
                  border: const OutlineInputBorder(),
                  helperText: _isForeign ? AppLang.t('স্বয়ংক্রিয়ভাবে হিসাব হয়েছে', 'Auto-calculated') : null,
                ),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                    ? AppLang.t('পরিমাণ দিন', 'Enter amount') : null,
              ),
              const SizedBox(height: 12),

              // Payment method
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: InputDecoration(
                  labelText: AppLang.t('পেমেন্ট পদ্ধতি', 'Payment Method'),
                  border: const OutlineInputBorder(),
                ),
                items: _methods.map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(AppLang.isEnglish.value ? m : (_methodLabels[m] ?? m)),
                )).toList(),
                onChanged: (v) => setState(() => _method = v ?? 'CASH'),
              ),
              const SizedBox(height: 12),

              // Reference
              TextField(
                controller: _ref,
                decoration: InputDecoration(
                  labelText: AppLang.t('ট্রানজেকশন রেফারেন্স (ঐচ্ছিক)', 'Transaction Reference (Optional)'),
                  border: const OutlineInputBorder(),
                  helperText: AppLang.t('bKash/Nagad TxnID বা ব্যাংক রেফারেন্স', 'bKash/Nagad TxnID or bank reference'),
                ),
              ),
              const SizedBox(height: 12),

              // Notes
              TextField(
                controller: _notes,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: AppLang.t('নোট (ঐচ্ছিক)', 'Notes (Optional)'),
                  border: const OutlineInputBorder(),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: cs.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppLang.t('দান নিবন্ধন করুন', 'Register Donation')),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

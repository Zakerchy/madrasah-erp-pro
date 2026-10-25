import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import 'donor_api.dart';
import 'widgets/islamic_slider.dart';

class DonorSignupScreen extends StatefulWidget {
  const DonorSignupScreen({super.key});

  @override
  State<DonorSignupScreen> createState() => _DonorSignupScreenState();
}

class _DonorSignupScreenState extends State<DonorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameBn = TextEditingController();
  final _nameEn = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pin = TextEditingController();
  final _pinConfirm = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();

  String _profession = '';
  final _professionOther = TextEditingController();
  String _country = 'BD';
  String _currencyPref = 'BDT';
  bool _loading = false;
  String? _error;

  static const _professions = [
    'ব্যবসায়ী', 'চাকরিজীবী', 'শিক্ষক', 'ডাক্তার', 'প্রকৌশলী', 'গৃহিণী', 'ছাত্র/ছাত্রী', 'অন্যান্য',
  ];

  static const _currencies = ['BDT', 'USD', 'GBP', 'EUR', 'SAR', 'AED', 'MYR', 'QAR', 'KWD', 'OMR'];

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_pin.text != _pinConfirm.text) {
      setState(() => _error = AppLang.t('পিন মিলছে না', 'PINs do not match'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final profession = _profession == 'অন্যান্য' ? _professionOther.text.trim() : _profession;
      final res = await DonorApi.register({
        'name_bn': _nameBn.text.trim(),
        'name_en': _nameEn.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'pin_hash': DonorApi.hashPin(_pin.text),
        'profession': profession,
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'country': _country,
        'currency_pref': _currencyPref,
      });
      if (!mounted) return;
      if (res['ok'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: Text(AppLang.t('রেজিস্ট্রেশন সম্পন্ন!', 'Registration Complete!')),
            content: Text(AppLang.t(
              'আপনার তথ্য জমা হয়েছে। অ্যাডমিন অনুমোদন করলে আপনাকে জানানো হবে। তারপর লগইন করতে পারবেন।',
              'Your application is submitted. You will be notified once approved. Then you can login.',
            )),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // back to login
                },
                child: Text(AppLang.t('ঠিক আছে', 'OK')),
              ),
            ],
          ),
        );
      } else {
        setState(() => _error = res['message'] as String? ?? AppLang.t('ত্রুটি হয়েছে', 'Error occurred'));
      }
    } catch (e) {
      setState(() => _error = AppLang.t('সংযোগ ত্রুটি', 'Connection error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameBn.dispose(); _nameEn.dispose(); _phone.dispose(); _email.dispose();
    _pin.dispose(); _pinConfirm.dispose(); _address.dispose(); _city.dispose();
    _professionOther.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(AppLang.t('দানকারী রেজিস্ট্রেশন', 'Donor Registration'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const IslamicSlider(height: 140),
              const SizedBox(height: 16),

              // Personal info
              _section(context, AppLang.t('ব্যক্তিগত তথ্য', 'Personal Info')),
              _field(_nameBn, AppLang.t('নাম (বাংলায়) *', 'Name (Bangla) *'),
                validator: (v) => (v?.isEmpty ?? true) ? AppLang.t('নাম দিন', 'Enter name') : null),
              const SizedBox(height: 10),
              _field(_nameEn, AppLang.t('Name (English)', 'Name (English)')),
              const SizedBox(height: 10),
              _field(_phone, AppLang.t('মোবাইল নম্বর *', 'Mobile Number *'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v?.length ?? 0) < 10 ? AppLang.t('সঠিক নম্বর দিন', 'Enter valid number') : null),
              const SizedBox(height: 10),
              _field(_email, AppLang.t('ইমেইল (ঐচ্ছিক)', 'Email (Optional)'),
                keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),

              // Profession
              DropdownButtonFormField<String>(
                initialValue: _profession.isEmpty ? null : _profession,
                decoration: InputDecoration(
                  labelText: AppLang.t('পেশা', 'Profession'),
                  border: const OutlineInputBorder(),
                ),
                items: _professions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _profession = v ?? ''),
              ),
              if (_profession == 'অন্যান্য') ...[
                const SizedBox(height: 10),
                _field(_professionOther, AppLang.t('পেশা লিখুন', 'Enter profession')),
              ],
              const SizedBox(height: 10),
              _field(_address, AppLang.t('ঠিকানা', 'Address')),
              const SizedBox(height: 10),
              _field(_city, AppLang.t('শহর/জেলা', 'City/District')),
              const SizedBox(height: 10),

              // Country & Currency
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _country,
                      decoration: InputDecoration(
                        labelText: AppLang.t('দেশ', 'Country'),
                        border: const OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BD', child: Text('বাংলাদেশ')),
                        DropdownMenuItem(value: 'SA', child: Text('সৌদি আরব')),
                        DropdownMenuItem(value: 'AE', child: Text('UAE')),
                        DropdownMenuItem(value: 'GB', child: Text('UK')),
                        DropdownMenuItem(value: 'US', child: Text('USA')),
                        DropdownMenuItem(value: 'MY', child: Text('Malaysia')),
                        DropdownMenuItem(value: 'QA', child: Text('Qatar')),
                        DropdownMenuItem(value: 'KW', child: Text('Kuwait')),
                        DropdownMenuItem(value: 'OM', child: Text('Oman')),
                        DropdownMenuItem(value: 'OTHER', child: Text('অন্যান্য')),
                      ],
                      onChanged: (v) => setState(() => _country = v ?? 'BD'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currencyPref,
                      decoration: InputDecoration(
                        labelText: AppLang.t('মুদ্রা', 'Currency'),
                        border: const OutlineInputBorder(),
                      ),
                      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _currencyPref = v ?? 'BDT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // PIN
              _section(context, AppLang.t('নিরাপত্তা পিন', 'Security PIN')),
              TextFormField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: AppLang.t('পিন (৪-৬ সংখ্যা) *', 'PIN (4-6 digits) *'),
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) => (v?.length ?? 0) < 4 ? AppLang.t('কমপক্ষে ৪ সংখ্যা', 'Min 4 digits') : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _pinConfirm,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: AppLang.t('পিন নিশ্চিত করুন *', 'Confirm PIN *'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) => v != _pin.text ? AppLang.t('পিন মিলছে না', 'PINs do not match') : null,
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
                    : Text(AppLang.t('রেজিস্ট্রেশন করুন', 'Register')),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
  );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
}

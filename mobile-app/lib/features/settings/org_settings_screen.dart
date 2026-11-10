import '../../shared/widgets/app_loader.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_lang.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/org_settings_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';
import '../home/pillar_icons.dart';

class _PillarEditState {
  String icon = 'book';
  final titleBn = TextEditingController();
  final titleEn = TextEditingController();
  final descBn = TextEditingController();
  final descEn = TextEditingController();

  void fill(OrgPillar p) {
    icon = p.icon;
    titleBn.text = p.titleBn;
    titleEn.text = p.titleEn;
    descBn.text = p.descBn;
    descEn.text = p.descEn;
  }

  OrgPillar toPillar() => OrgPillar(
        icon: icon,
        titleBn: titleBn.text.trim(),
        titleEn: titleEn.text.trim(),
        descBn: descBn.text.trim(),
        descEn: descEn.text.trim(),
      );

  void dispose() {
    titleBn.dispose();
    titleEn.dispose();
    descBn.dispose();
    descEn.dispose();
  }
}

class OrgSettingsScreen extends StatefulWidget {
  const OrgSettingsScreen({super.key});

  @override
  State<OrgSettingsScreen> createState() => _OrgSettingsScreenState();
}

class _OrgSettingsScreenState extends State<OrgSettingsScreen> {
  final _api = ApiService();
  final _nameBn = TextEditingController();
  final _nameEn = TextEditingController();
  final _bankDetails = TextEditingController();
  final _aboutBn = TextEditingController();
  final _contactPhone = TextEditingController();
  final _pillars = List.generate(3, (_) => _PillarEditState());
  String _logoUrl = '';
  Uint8List? _pickedBytes;
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final p in _pillars) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    await OrgSettings.load(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _nameBn.text = OrgSettings.nameBn;
      _nameEn.text = OrgSettings.nameEn;
      _bankDetails.text = OrgSettings.bankDetailsBn;
      _aboutBn.text = OrgSettings.aboutBn;
      _contactPhone.text = OrgSettings.contactPhone;
      _logoUrl = OrgSettings.logoUrl;
      for (var i = 0; i < _pillars.length && i < OrgSettings.pillars.length; i++) {
        _pillars[i].fill(OrgSettings.pillars[i]);
      }
      _loading = false;
    });
  }

  Future<void> _pickLogo() async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLang.t('ছবি বাছাই ব্যর্থ, আবার চেষ্টা করুন', 'Could not open image picker, please try again')),
      ));
      return;
    }
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() { _pickedBytes = bytes; _uploading = true; });
    final res = await _api.post('adminUploadOrgLogo', {
      'user_role': SessionService.role,
      'payload': {'base64': base64Encode(bytes), 'mime_type': 'image/png'},
    });
    if (mounted) {
      if (res['ok'] == true) {
        setState(() => _logoUrl = res['url'] as String);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] as String? ?? AppLang.t('আপলোড ব্যর্থ', 'Upload failed')),
        ));
      }
      setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final res = await _api.post('setOrgSettings', {
      'user_role': SessionService.role,
      'payload': {
        'name_bn': _nameBn.text.trim(),
        'name_en': _nameEn.text.trim(),
        'logo_url': _logoUrl,
        'bank_details_bn': _bankDetails.text.trim(),
        'about_bn': _aboutBn.text.trim(),
        'contact_phone': _contactPhone.text.trim(),
        'pillars_json': jsonEncode(_pillars.map((p) => p.toPillar().toMap()).toList()),
      },
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['ok'] == true ? AppLang.t('সংরক্ষিত হয়েছে', 'Saved')
            : (res['message'] as String? ?? AppLang.t('ত্রুটি', 'Error'))),
      ));
      if (res['ok'] == true) await OrgSettings.load(forceRefresh: true);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: AppLang.t('প্রতিষ্ঠানের তথ্য', 'Organization Details'),
      body: _loading
          ? const Center(child: AppLoader())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _uploading ? null : _pickLogo,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: _pickedBytes != null
                              ? MemoryImage(_pickedBytes!)
                              : (_logoUrl.isNotEmpty ? NetworkImage(_logoUrl) : null) as ImageProvider?,
                          child: (_pickedBytes == null && _logoUrl.isEmpty)
                              ? const Icon(Icons.business, size: 40)
                              : null,
                        ),
                        if (_uploading) const CircularProgressIndicator(),
                        const Positioned(
                          bottom: 0, right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            child: Icon(Icons.edit, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Text(AppLang.t('লোগো পরিবর্তন করতে ট্যাপ করুন', 'Tap to change logo'),
                    style: const TextStyle(fontSize: 12))),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameBn,
                  decoration: InputDecoration(labelText: AppLang.t('প্রতিষ্ঠানের নাম (বাংলা)', 'Organization Name (Bangla)')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameEn,
                  decoration: InputDecoration(labelText: AppLang.t('প্রতিষ্ঠানের নাম (ইংরেজি)', 'Organization Name (English)')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bankDetails,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: AppLang.t('ব্যাংক/লেনদেন বিবরণ', 'Bank/Transaction Details'),
                    helperText: AppLang.t(
                      'এটা দানকারী অ্যাপের top bar থেকে সবাই দেখতে পাবে (bKash/bank account ইত্যাদি লিখুন)',
                      'Visible to all donors from the app top bar (write bKash/bank account etc.)',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _aboutBn,
                  minLines: 4,
                  maxLines: 10,
                  decoration: InputDecoration(
                    labelText: AppLang.t('আমাদের সম্পর্কে / মিশন', 'About Us / Mission'),
                    helperText: AppLang.t(
                      'এটা পাবলিক হোমপেজে (লগইনের আগে) সবাই দেখতে পাবেন',
                      'Shown to everyone on the public home page (before login)',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contactPhone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: AppLang.t('যোগাযোগ নম্বর (বড় অনুদানের জন্য কল)', 'Contact Number (for large-donation calls)'),
                    helperText: AppLang.t(
                      'বড় অনুদানের (১০,০০০৳+) ক্ষেত্রে ভিজিটরকে এই নম্বরে কল করার অপশন দেখানো হবে',
                      'Shown as a call option to visitors making a large (৳10,000+) donation',
                    ),
                    prefixIcon: const Icon(Icons.call_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLang.t('হোমপেজের ৩টি বৈশিষ্ট্য (পিলার)', 'Homepage 3 Pillars'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLang.t(
                    'পাবলিক হোমপেজে "আমাদের সম্পর্কে"-এর নিচে এই ৩টি কার্ড দেখানো হয়',
                    'These 3 cards appear below "About Us" on the public home page',
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _pillars.length; i++) ...[
                  _PillarEditor(index: i, state: _pillars[i], onChanged: () => setState(() {})),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppLang.t('সংরক্ষণ করুন', 'Save')),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLang.t(
                    'নোট: Android app icon settings থেকে সাথে সাথে বদলায় না — পরবর্তী APK বিল্ডে এই লোগো ব্যবহার হবে।',
                    'Note: The Android app icon does not change instantly from here — it will be used in the next APK build.',
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
    );
  }
}

class _PillarEditor extends StatelessWidget {
  final int index;
  final _PillarEditState state;
  final VoidCallback onChanged;
  const _PillarEditor({required this.index, required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${AppLang.t('পিলার', 'Pillar')} ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              DropdownButton<String>(
                value: state.icon,
                items: pillarIconChoices.keys
                    .map((k) => DropdownMenuItem(
                          value: k,
                          child: Icon(pillarIconChoices[k]),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) state.icon = v;
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: state.titleBn,
                  decoration: InputDecoration(labelText: AppLang.t('শিরোনাম (বাংলা)', 'Title (Bangla)')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: state.titleEn,
                  decoration: InputDecoration(labelText: AppLang.t('শিরোনাম (ইংরেজি)', 'Title (English)')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: state.descBn,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: AppLang.t('বিবরণ (বাংলা)', 'Description (Bangla)')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: state.descEn,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: AppLang.t('বিবরণ (ইংরেজি)', 'Description (English)')),
          ),
        ],
      ),
    );
  }
}

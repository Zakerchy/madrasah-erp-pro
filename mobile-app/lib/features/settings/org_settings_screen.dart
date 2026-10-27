import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_lang.dart';
import '../../shared/services/api_service.dart';
import '../../shared/services/org_settings_service.dart';
import '../../shared/services/session_service.dart';
import '../../shared/widgets/base_scaffold.dart';

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

  Future<void> _load() async {
    await OrgSettings.load(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _nameBn.text = OrgSettings.nameBn;
      _nameEn.text = OrgSettings.nameEn;
      _bankDetails.text = OrgSettings.bankDetailsBn;
      _logoUrl = OrgSettings.logoUrl;
      _loading = false;
    });
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
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
          ? const Center(child: CircularProgressIndicator())
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
                const SizedBox(height: 20),
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

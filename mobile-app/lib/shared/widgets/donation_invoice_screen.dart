import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_lang.dart';
import '../services/file_save_service.dart';
import '../services/org_settings_service.dart';
import 'donation_invoice_view.dart';

/// Full-screen receipt preview with download/share — used from both the
/// admin transactions tab and the donor's own ledger.
class DonationInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic> txn;
  final String donorName;
  final String donorPhone;

  const DonationInvoiceScreen({
    super.key,
    required this.txn,
    required this.donorName,
    required this.donorPhone,
  });

  @override
  State<DonationInvoiceScreen> createState() => _DonationInvoiceScreenState();
}

class _DonationInvoiceScreenState extends State<DonationInvoiceScreen> {
  final _repaintKey = GlobalKey();
  bool _loadingOrg = !OrgSettings.loaded;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (!OrgSettings.loaded) {
      OrgSettings.load().then((_) {
        if (mounted) setState(() => _loadingOrg = false);
      });
    }
  }

  String get _filename => 'receipt_${widget.txn['id'] ?? 'donation'}.png';

  Future<Uint8List?> _capture() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _download() async {
    setState(() => _busy = true);
    final bytes = await _capture();
    if (bytes != null) {
      final saved = await fileSaveService.download(bytes, _filename);
      if (!saved) {
        // Non-web platform — fall back to the share sheet (lets the user save).
        await Share.shareXFiles([XFile.fromData(bytes, mimeType: 'image/png', name: _filename)]);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    final bytes = await _capture();
    if (bytes != null) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: _filename)],
        text: AppLang.t('${OrgSettings.nameBn} — দান রশিদ', '${OrgSettings.nameEn} — Donation Receipt'),
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLang.t('দান রশিদ', 'Donation Receipt')),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: AppLang.t('ডাউনলোড', 'Download'),
            onPressed: _busy ? null : _download,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: AppLang.t('শেয়ার করুন', 'Share'),
            onPressed: _busy ? null : _share,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF14786B),
      body: _loadingOrg
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: DonationInvoiceView(
                        txn: widget.txn,
                        donorName: widget.donorName,
                        donorPhone: widget.donorPhone,
                      ),
                    ),
                  ),
                ),
                if (_busy)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            ),
    );
  }
}

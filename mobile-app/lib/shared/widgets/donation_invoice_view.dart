import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_lang.dart';
import '../constants/fund_types.dart';
import '../services/org_settings_service.dart';

/// The printable/shareable donation receipt — rendered to a fixed-size
/// canvas so it captures identically as a PNG regardless of screen size.
class DonationInvoiceView extends StatelessWidget {
  final Map<String, dynamic> txn;
  final String donorName;
  final String donorPhone;

  const DonationInvoiceView({
    super.key,
    required this.txn,
    required this.donorName,
    required this.donorPhone,
  });

  static const double width = 720;

  String _money(dynamic v) => NumberFormat('#,##0.##', 'en_US').format(_num(v));
  double _num(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0);

  String _methodLabel(String? m) {
    const map = {
      'CASH': 'নগদ', 'BANK_TRANSFER': 'ব্যাংক ট্রান্সফার',
      'MOBILE_BANKING': 'মোবাইল ব্যাংকিং (bKash/Nagad)', 'CHEQUE': 'চেক', 'OTHER': 'অন্যান্য',
    };
    return AppLang.isEnglish.value ? (m ?? '') : (map[m] ?? (m ?? ''));
  }

  String _date(dynamic v) {
    final s = (v as String?) ?? '';
    if (s.length < 10) return s;
    try {
      final d = DateTime.parse(s);
      return DateFormat('dd MMM yyyy, hh:mm a').format(d);
    } catch (_) {
      return s.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (txn['status'] as String?) ?? 'CONFIRMED';
    final confirmed = status == 'CONFIRMED';
    final currency = (txn['currency'] as String?) ?? 'BDT';
    final isForeign = currency != 'BDT';
    final ft = FundTypes.byKey(txn['fund_type'] as String?);
    final fundLabel = AppLang.isEnglish.value
        ? (ft?.labelEn ?? (txn['fund_type'] as String? ?? ''))
        : (ft?.labelBn ?? (txn['fund_type'] as String? ?? ''));
    final charge = _num(txn['transfer_charge_bdt']);
    final netAmount = txn['net_amount_bdt'] == null || txn['net_amount_bdt'] == ''
        ? _num(txn['amount_bdt'])
        : _num(txn['net_amount_bdt']);
    final orgName = AppLang.isEnglish.value && OrgSettings.nameEn.isNotEmpty
        ? OrgSettings.nameEn
        : OrgSettings.nameBn;

    return Container(
      width: width,
      padding: const EdgeInsets.all(28),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: org branding
          Row(
            children: [
              if (OrgSettings.logoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    OrgSettings.logoUrl,
                    width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 50, color: Color(0xFF14786B)),
                  ),
                )
              else
                const Icon(Icons.business, size: 50, color: Color(0xFF14786B)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(orgName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF14786B))),
                    if (OrgSettings.bankDetailsBn.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(OrgSettings.bankDetailsBn,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: confirmed ? const Color(0xFFE6F6F1) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: confirmed ? const Color(0xFF14786B) : Colors.orange),
                ),
                child: Text(
                  confirmed ? AppLang.t('নিশ্চিত', 'CONFIRMED') : AppLang.t('অপেক্ষামাণ', 'PENDING'),
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: confirmed ? const Color(0xFF14786B) : Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 16),

          Center(
            child: Text(AppLang.t('দান রশিদ', 'DONATION RECEIPT'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(child: _kv(AppLang.t('রশিদ নং', 'Receipt No'), (txn['id'] as String?) ?? '')),
              Expanded(child: _kv(AppLang.t('তারিখ', 'Date'),
                  _date(confirmed ? (txn['confirmed_at'] ?? txn['created_at']) : txn['created_at']))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _kv(AppLang.t('দানকারী', 'Donor'), donorName)),
              Expanded(child: _kv(AppLang.t('মোবাইল', 'Phone'), donorPhone)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _kv(AppLang.t('খাত', 'Fund'), fundLabel)),
              Expanded(child: _kv(AppLang.t('পদ্ধতি', 'Method'), _methodLabel(txn['payment_method'] as String?))),
            ],
          ),
          if ((txn['txn_reference'] as String?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            _kv(AppLang.t('রেফারেন্স', 'Reference'), txn['txn_reference'] as String),
          ],
          if (isForeign) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _kv(AppLang.t('বিদেশী পরিমাণ', 'Foreign Amount'),
                    '${txn['amount_foreign']} $currency')),
                if (confirmed)
                  Expanded(child: _kv(AppLang.t('বিনিময় হার', 'Exchange Rate'), '৳${txn['exchange_rate']}')),
              ],
            ),
          ],
          if (confirmed && charge > 0) ...[
            const SizedBox(height: 10),
            _kv(AppLang.t('ব্যাংক/বিকাশ চার্জ', 'Bank/bKash Charge'), '৳${_money(charge)}'),
          ],

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  confirmed && charge > 0
                      ? AppLang.t('প্রতিষ্ঠান পেয়েছে', 'Madrasah Received')
                      : AppLang.t('মোট পরিমাণ', 'Total Amount'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '৳ ${_money(confirmed && charge > 0 ? netAmount : txn['amount_bdt'])}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF14786B)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLang.t('জাযাকাল্লাহু খাইরান — আপনার দানের জন্য ধন্যবাদ।',
                    'JazakAllahu Khayran — thank you for your donation.'),
                style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 24),
                  Container(width: 120, height: 1, color: Colors.black38),
                  const SizedBox(height: 4),
                  Text(AppLang.t('কর্তৃপক্ষ', 'Authority'), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppLang.t('এটি একটি সিস্টেম-জেনারেটেড রশিদ।', 'This is a system-generated receipt.'),
            style: const TextStyle(fontSize: 10, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
    ],
  );
}

import 'dart:convert';

import 'api_service.dart';

class OrgPillar {
  final String icon;
  final String titleBn;
  final String titleEn;
  final String descBn;
  final String descEn;

  const OrgPillar({
    required this.icon,
    required this.titleBn,
    required this.titleEn,
    required this.descBn,
    required this.descEn,
  });

  factory OrgPillar.fromMap(Map<String, dynamic> m) => OrgPillar(
        icon: (m['icon'] as String?) ?? 'book',
        titleBn: (m['title_bn'] as String?) ?? '',
        titleEn: (m['title_en'] as String?) ?? '',
        descBn: (m['desc_bn'] as String?) ?? '',
        descEn: (m['desc_en'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
        'icon': icon,
        'title_bn': titleBn,
        'title_en': titleEn,
        'desc_bn': descBn,
        'desc_en': descEn,
      };
}

/// Organization branding + bank/transaction details — fetched once (no auth
/// needed) and shared across the staff login screen, donor login screen,
/// donor home screen and invoices.
class OrgSettings {
  OrgSettings._();

  static String nameBn = 'মাদ্রাসা ERP';
  static String nameEn = 'Madrasah ERP';
  static String logoUrl = '';
  static String bankDetailsBn = '';
  static String aboutBn = '';
  static String contactPhone = '';
  static List<OrgPillar> pillars = const [];
  static bool loaded = false;

  static Future<void> load({bool forceRefresh = false}) async {
    try {
      final res = await ApiService().get('getOrgSettings', forceRefresh: forceRefresh);
      if (res['ok'] == true) {
        nameBn = (res['name_bn'] as String?)?.trim().isNotEmpty == true ? res['name_bn'] as String : nameBn;
        nameEn = (res['name_en'] as String?)?.trim().isNotEmpty == true ? res['name_en'] as String : nameEn;
        logoUrl = (res['logo_url'] as String?) ?? '';
        bankDetailsBn = (res['bank_details_bn'] as String?) ?? '';
        aboutBn = (res['about_bn'] as String?) ?? '';
        contactPhone = (res['contact_phone'] as String?) ?? '';
        final pillarsJson = (res['pillars_json'] as String?) ?? '';
        if (pillarsJson.isNotEmpty) {
          try {
            final list = jsonDecode(pillarsJson) as List;
            pillars = list
                .map((e) => OrgPillar.fromMap(e as Map<String, dynamic>))
                .toList();
          } catch (_) {
            // Keep previous pillars on malformed JSON.
          }
        }
        loaded = true;
      }
    } catch (_) {
      // Keep defaults — login/home screens must still render without this.
    }
  }
}

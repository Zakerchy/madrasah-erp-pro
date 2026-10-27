import 'api_service.dart';

/// Organization branding + bank/transaction details — fetched once (no auth
/// needed) and shared across the staff login screen, donor login screen,
/// donor home screen and invoices.
class OrgSettings {
  OrgSettings._();

  static String nameBn = 'মাদ্রাসা ERP';
  static String nameEn = 'Madrasah ERP';
  static String logoUrl = '';
  static String bankDetailsBn = '';
  static bool loaded = false;

  static Future<void> load({bool forceRefresh = false}) async {
    try {
      final res = await ApiService().get('getOrgSettings', forceRefresh: forceRefresh);
      if (res['ok'] == true) {
        nameBn = (res['name_bn'] as String?)?.trim().isNotEmpty == true ? res['name_bn'] as String : nameBn;
        nameEn = (res['name_en'] as String?)?.trim().isNotEmpty == true ? res['name_en'] as String : nameEn;
        logoUrl = (res['logo_url'] as String?) ?? '';
        bankDetailsBn = (res['bank_details_bn'] as String?) ?? '';
        loaded = true;
      }
    } catch (_) {
      // Keep defaults — login/home screens must still render without this.
    }
  }
}

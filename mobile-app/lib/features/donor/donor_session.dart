import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores donor auth state in local prefs — separate from staff session.
class DonorSession {
  static const _prefKey = 'donor_session_v1';

  static String? _donorId;
  static String? _donorToken;
  static Map<String, dynamic>? _donor;

  static bool get isLoggedIn => _donorId != null && _donorToken != null;
  static String? get donorId => _donorId;
  static String? get donorToken => _donorToken;
  static String get nameBn => (_donor?['name_bn'] ?? '') as String;
  static String get currencyPref => (_donor?['currency_pref'] ?? 'BDT') as String;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _donorId = map['donor_id'] as String?;
      _donorToken = map['donor_token'] as String?;
      _donor = map['donor'] as Map<String, dynamic>?;
    } catch (_) {}
  }

  static Future<void> save(String donorId, String token, Map<String, dynamic> donor) async {
    _donorId = donorId;
    _donorToken = token;
    _donor = donor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode({
      'donor_id': donorId,
      'donor_token': token,
      'donor': donor,
    }));
  }

  static Future<void> clear() async {
    _donorId = null;
    _donorToken = null;
    _donor = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  /// Attach auth fields to any donor API payload.
  static Map<String, dynamic> authParams() => {
    'donor_id': _donorId ?? '',
    'donor_token': _donorToken ?? '',
  };
}

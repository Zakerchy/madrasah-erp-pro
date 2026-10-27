import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/app_config.dart';

/// Donor-facing API calls — no staff session required.
class DonorApi {
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  static Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse(AppConfig.appsScriptUrl))
        ..headers['Content-Type'] = kIsWeb ? 'text/plain;charset=utf-8' : 'application/json'
        ..body = jsonEncode(body);
      final streamed = await client.send(req).timeout(const Duration(seconds: 25));
      String? location;
      if (streamed.statusCode == 302 || streamed.statusCode == 301) {
        location = streamed.headers['location'];
      }
      if (location != null) {
        final res = await client.get(Uri.parse(location)).timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
        throw Exception('Redirect HTTP ${res.statusCode}');
      }
      final bodyStr = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) return jsonDecode(bodyStr) as Map<String, dynamic>;
      throw Exception('HTTP ${streamed.statusCode}');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> payload) =>
      _post({'action': 'donorRegister', 'payload': payload});

  static Future<Map<String, dynamic>> login(String phone, String pin) =>
      _post({'action': 'donorLogin', 'payload': {
        'phone': phone,
        'pin_hash': hashPin(pin),
      }});

  static Future<Map<String, dynamic>> listOpportunities() =>
      _post({'action': 'listDonationOpportunities'});

  static Future<Map<String, dynamic>> uploadSlip(
    String donorId,
    String token,
    String base64,
    String mimeType,
  ) =>
      _post({'action': 'donorUploadSlip', 'payload': {
        'donor_id': donorId,
        'donor_token': token,
        'base64': base64,
        'mime_type': mimeType,
      }});

  static Future<Map<String, dynamic>> donate(
    String donorId,
    String token,
    Map<String, dynamic> payload,
  ) =>
      _post({'action': 'donorDonate', 'payload': {
        'donor_id': donorId,
        'donor_token': token,
        ...payload,
      }});

  static Future<Map<String, dynamic>> myDashboard(String donorId, String token) =>
      _post({'action': 'donorMyDashboard', 'payload': {
        'donor_id': donorId,
        'donor_token': token,
      }});

  static Future<Map<String, dynamic>> myTransactions(String donorId, String token) =>
      _post({'action': 'donorMyTransactions', 'payload': {
        'donor_id': donorId,
        'donor_token': token,
      }});

  static Future<Map<String, dynamic>> myNotifications(String donorId, String token) =>
      _post({'action': 'donorMyNotifications', 'payload': {
        'donor_id': donorId,
        'donor_token': token,
      }});
}

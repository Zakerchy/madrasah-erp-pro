import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';

class ApiService {
  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(String action, {Map<String, String>? query}) async {
    final params = {'action': action, ...?query};
    final uri = Uri.parse(AppConfig.apiBaseUrl).replace(queryParameters: params);
    final res = await _client.get(uri).timeout(const Duration(seconds: 30));
    return _parse(res);
  }

  Future<Map<String, dynamic>> post(String action, Map<String, dynamic> payload) async {
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    final body = {'action': action, ...payload};
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    return _parse(res);
  }

  Map<String, dynamic> _parse(http.Response res) {
    if (res.body.isEmpty) {
      return {'ok': false, 'message': 'Empty server response'};
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'ok': false, 'message': 'Invalid response format'};
  }
}

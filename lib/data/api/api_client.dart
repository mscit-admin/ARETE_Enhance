import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';

/// Raised for any API failure; [message] is safe to show to the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;

  /// Machine-readable server code, e.g. 'account_suspended'.
  final String? code;
  @override
  String toString() => message;
}

/// Thin HTTP client for the ARETE backend. Handles the auth token (persisted in
/// shared_preferences), JSON encoding/decoding and error mapping.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  static const _tokenKey = 'api_token_v1';
  String? _token;

  /// Invoked when the server reports the account has been suspended, so the
  /// app can sign the user out immediately. Wired up in main().
  void Function()? onSuspended;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> loadToken() async {
    if (_token != null) return _token;
    _token = (await _prefs).getString(_tokenKey);
    return _token;
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final p = await _prefs;
    if (token == null) {
      await p.remove(_tokenKey);
    } else {
      await p.setString(_tokenKey, token);
    }
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final t = await loadToken();
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true}) =>
      _send(() async => _http
          .get(ApiConfig.uri(path), headers: await _headers(auth: auth))
          .timeout(ApiConfig.timeout));

  Future<dynamic> post(String path, Map<String, dynamic> body,
          {bool auth = false}) =>
      _send(() async => _http
          .post(ApiConfig.uri(path),
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(ApiConfig.timeout));

  Future<dynamic> put(String path, Map<String, dynamic> body,
          {bool auth = true}) =>
      _send(() async => _http
          .put(ApiConfig.uri(path),
              headers: await _headers(auth: auth), body: jsonEncode(body))
          .timeout(ApiConfig.timeout));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request();
    } catch (_) {
      throw const ApiException(
          'Can\'t reach the server. Check your connection and try again.');
    }

    dynamic decoded;
    if (res.body.isNotEmpty) {
      try {
        decoded = jsonDecode(res.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    final message = (decoded is Map && decoded['error'] is String)
        ? decoded['error'] as String
        : 'Request failed (${res.statusCode}).';
    final code = (decoded is Map && decoded['code'] is String)
        ? decoded['code'] as String
        : null;

    // A freeze that lands mid-session: sign the user out immediately.
    if (res.statusCode == 403 && code == 'account_suspended') {
      onSuspended?.call();
    }

    throw ApiException(message, statusCode: res.statusCode, code: code);
  }
}

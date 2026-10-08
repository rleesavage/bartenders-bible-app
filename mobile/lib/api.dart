import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class Api {
  static const base = 'https://webolium.com/bartenders/api/v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? token;

  Future<void> loadToken() async {
    token = await _storage.read(key: 'bb_api_token');
  }

  Future<void> saveToken(String value) async {
    token = value;
    await _storage.write(key: 'bb_api_token', value: value);
  }

  Future<void> clearToken() async {
    token = null;
    await _storage.delete(key: 'bb_api_token');
  }

  Map<String, String> get _headers => <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
        if (token != null) 'X-BB-Token': token!,
      };

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('The server returned an unreadable response.');
    }

    if (response.statusCode >= 400 || data['ok'] != true) {
      throw ApiException((data['error'] ?? 'Request failed.').toString());
    }
    return data;
  }

  Future<Map<String, dynamic>> get(
    String path, [
    Map<String, String>? query,
  ]) async {
    var uri = Uri.parse('$base/$path');
    if (query != null) uri = uri.replace(queryParameters: query);
    return _decode(await http.get(uri, headers: _headers));
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _decode(
      await http.post(
        Uri.parse('$base/$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _decode(
      await http.delete(
        Uri.parse('$base/$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await post('login.php', <String, dynamic>{
      'email': email,
      'password': password,
      'device': 'Bartenders Bible mobile',
    });
    await saveToken(data['token'].toString());
    return data;
  }

  Future<void> logout() async {
    try {
      if (token != null) await post('logout.php', <String, dynamic>{});
    } finally {
      await clearToken();
    }
  }
}

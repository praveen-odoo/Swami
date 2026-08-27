import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiService {
  final String baseUrl = AppConstants.baseUrl;
  final String code = AppConstants.subscriptionCode;
  final String languageCode; // e.g., 'en' or 'hi'
  
  static const String _tokenKey = 'auth_token';

  ApiService({this.languageCode = 'hi'});

  /// Odoo expects specific locale strings like 'en_US' or 'hi_IN'
  String get odooLang => languageCode == 'en' ? 'en_US' : 'hi_IN';

  Future<String?> get _token async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null && token.startsWith('simulated_')) {
      await prefs.remove(_tokenKey);
      return null;
    }
    return token;
  }

  Future<void> setToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Map<String, String> _headers(String? token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Accept-Language': odooLang, // Send full Odoo locale
    };
  }

  Future<dynamic> get(String path, {bool authenticated = true}) async {
    final token = authenticated ? await _token : null;
    
    // Odoo often looks for 'lang' in query params
    final separator = path.contains('?') ? '&' : '?';
    final url = Uri.parse('$baseUrl/api/v1/$code$path${separator}lang=$odooLang');
    
    final headers = _headers(token);
    if (token != null) headers['Authorization'] = 'Bearer $token';

    debugPrint('🚀 [ApiService] Odoo GET: $url');
    debugPrint('📋 [ApiService] GET Headers: $headers');

    try {
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ [ApiService] GET FAILED: $e');
      rethrow;
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool authenticated = true}) async {
    final token = authenticated ? await _token : null;
    
    final separator = path.contains('?') ? '&' : '?';
    final url = Uri.parse('$baseUrl/api/v1/$code$path${separator}lang=$odooLang');
    
    final headers = _headers(token);
    if (token != null) headers['Authorization'] = 'Bearer $token';

    debugPrint('🚀 [ApiService] Odoo POST: $url');
    debugPrint('📋 [ApiService] POST Headers: $headers');
    if (body != null) {
      debugPrint('📦 [ApiService] POST Body: ${jsonEncode(body)}');
    } else {
      debugPrint('📦 [ApiService] POST Body: (empty)');
    }

    try {
      final response = await http.post(
        url, 
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ [ApiService] POST FAILED: $e');
      rethrow;
    }
  }

  Future<dynamic> uploadFile(String path, File file, {bool authenticated = true}) async {
    final token = authenticated ? await _token : null;
    final url = Uri.parse('$baseUrl/api/v1/$code$path?lang=$odooLang');

    debugPrint('🚀 [ApiService] Odoo Upload: $url');
    final request = http.MultipartRequest('POST', url);
    
    final headers = _headers(token);
    if (token != null) headers['Authorization'] = 'Bearer $token';
    request.headers.addAll(headers);

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 404) {
        debugPrint('❌ [ApiService] Upload FAILED_404: Endpoint not found ($url)');
        throw Exception('Upload endpoint not found (404)');
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ [ApiService] Upload FAILED: $e');
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    debugPrint('📥 [ApiService] Raw Response Body: ${response.body}');
    debugPrint('📥 [ApiService] Response Status Code: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        debugPrint('📥 [ApiService] Empty response body');
        return null;
      }
      try {
        final decoded = jsonDecode(response.body);
        debugPrint('📥 [ApiService] Decoded JSON Object: $decoded');
        return decoded;
      } catch (e) {
        debugPrint('❌ [ApiService] JSON Decode Error: $e');
        return response.body;
      }
    } else if (response.statusCode == 401) {
      debugPrint('🚨 [ApiService] 401 Unauthorized - Clearing token');
      setToken(null);
      throw Exception('Session expired.');
    } else {
      debugPrint('❌ [ApiService] API Error: ${response.statusCode}');
      throw Exception('API Error: ${response.statusCode}');
    }
  }
}

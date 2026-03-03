import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ContactService {
  static const String _baseUrl = 'https://clever-it-hazel.vercel.app';

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> uploadContacts(List<Map<String, dynamic>> contacts) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/contacts/upload');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'contacts': contacts,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('uploadContacts', response);
    }

    return jsonDecode(response.body);
  }

  Future<void> grantConsent(String consentType) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/contacts/consent');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'consentType': consentType,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('grantConsent', response);
    }
  }

  Future<void> revokeConsent(String consentType) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/contacts/consent');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'consentType': consentType,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('revokeConsent', response);
    }
  }

  Future<Map<String, dynamic>> getConsentStatus() async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/contacts/consent/status');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('getConsentStatus', response);
    }

    return jsonDecode(response.body);
  }

  void _handleError(String operation, http.Response response) {
    final status = response.statusCode;
    String message = '$operation failed ($status)';

    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) {
        message = body['message'] as String;
      } else if (body is Map && body['error'] is String) {
        message = body['error'] as String;
      }
    } catch (_) {}

    debugPrint('ContactService $operation error: ${response.body}');
    throw Exception(message);
  }
}

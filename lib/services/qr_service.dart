import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class QrService {
  static const String _baseUrl = 'https://clever-it-hazel.vercel.app';

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> getMyQr() async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/qr/me');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('getMyQr', response);
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> resolveQr(String qrToken) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/qr/resolve/$qrToken');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('resolveQr', response);
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

    debugPrint('QrService $operation error: ${response.body}');
    throw Exception(message);
  }
}

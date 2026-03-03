import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class BloodService {
  static const String _baseUrl = 'https://clever-it-hazel.vercel.app';

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: queryParameters);
  }

  Future<List<dynamic>> getBloodCamps({
    String? status,
    String? city,
    String? bloodGroup,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = {
      if (status != null) 'status': status,
      if (city != null) 'city': city,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = _buildUri('/api/blood-camps', queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('getBloodCamps', response);
    }

    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getBloodRequests({
    String? bloodGroup,
    String? urgency,
    String? city,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = {
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (urgency != null) 'urgency': urgency,
      if (city != null) 'city': city,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = _buildUri('/api/blood-requests', queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('getBloodRequests', response);
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

    debugPrint('BloodService $operation error: ${response.body}');
    throw Exception(message);
  }
}

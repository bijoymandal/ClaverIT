import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class EventService {
  static const String _baseUrl = 'https://clever-it-hazel.vercel.app';

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/events');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('createEvent', response);
    }

    return jsonDecode(response.body);
  }

  Future<List<dynamic>> listEvents({
    String? view,
    String? eventType,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = {
      if (view != null) 'view': view,
      if (eventType != null) 'eventType': eventType,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = _buildUri('/api/events', queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('listEvents', response);
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

    debugPrint('EventService $operation error: ${response.body}');
    throw Exception(message);
  }
}

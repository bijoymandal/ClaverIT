import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AppointmentService {
  static const String _baseUrl = 'https://clever-it-hazel.vercel.app';

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> createAppointment({
    required String businessId,
    required String serviceId,
    required String scheduledAt,
    String? notes,
  }) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/appointments');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'businessId': businessId,
        'serviceId': serviceId,
        'scheduledAt': scheduledAt,
        if (notes != null) 'notes': notes,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('createAppointment', response);
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> listMyAppointments({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = {
      if (status != null) 'status': status,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = _buildUri('/api/appointments/me', queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('listMyAppointments', response);
    }

    return jsonDecode(response.body);
  }

  Future<void> cancelAppointment(String id, {String? reason}) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/appointments/$id/cancel');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (reason != null) 'reason': reason,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('cancelAppointment', response);
    }
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

    debugPrint('AppointmentService $operation error: ${response.body}');
    throw Exception(message);
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class TaskService {
  static const String _baseUrl = 'https://clever-it-hazel.vercel.app';

  Uri _buildUri(String path) {
    return Uri.parse('$_baseUrl$path');
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/tasks');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // If endpoint doesn't exist, return empty list for now
      if (response.statusCode == 404) return [];
      _handleError('getTasks', response);
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createTask(String title, {String description = ''}) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/tasks');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('createTask', response);
    }

    return jsonDecode(response.body);
  }

  Future<void> toggleTask(String id, bool isCompleted) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/tasks/$id');
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'isCompleted': isCompleted,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('toggleTask', response);
    }
  }

  Future<void> deleteTask(String id) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/tasks/$id');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('deleteTask', response);
    }
  }

  void _handleError(String operation, http.Response response) {
    final status = response.statusCode;
    String message = '$operation failed ($status)';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        message = body['message'];
      }
    } catch (_) {}
    throw Exception(message);
  }
}

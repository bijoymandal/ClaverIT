import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ChatService {
  static const String _baseUrl = 'https://clever-it-hazel.vercel.app';

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: queryParameters);
  }

  Future<List<dynamic>> getConversations() async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/chat/conversations');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('getConversations', response);
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getConversation(String id) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/chat/conversations/$id');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('getConversation', response);
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createConversation({
    required List<String> participantIds,
    String? name,
    bool isGroup = false,
  }) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/chat/conversations');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'participantIds': participantIds,
        'name': name,
        'isGroup': isGroup,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('createConversation', response);
    }

    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getMessages(String conversationId, {int limit = 50, String? before}) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = {
      'limit': limit.toString(),
      if (before != null) 'before': before,
    };

    final uri = _buildUri('/api/chat/conversations/$conversationId/messages', queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('getMessages', response);
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    String? messageType,
    String? clientMessageId,
  }) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/chat/messages');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'conversationId': conversationId,
        'content': content,
        'messageType': messageType ?? 'text',
        'clientMessageId': clientMessageId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('sendMessage', response);
    }

    return jsonDecode(response.body);
  }

  Future<void> markRead(String conversationId) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/chat/conversations/$conversationId/read');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('markRead', response);
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

    debugPrint('ChatService $operation error: ${response.body}');
    throw Exception(message);
  }
}

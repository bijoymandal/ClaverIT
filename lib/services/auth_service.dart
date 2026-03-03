import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VerifyOtpResult {
  final bool isNewUser;
  final String? token;
  final Map<String, dynamic>? data;

  VerifyOtpResult({required this.isNewUser, this.token, this.data});

  bool get hasToken => token != null && token!.isNotEmpty;
}

class AuthService {
  static const String _authTokenKey = 'auth_token';
  static const String _baseUrl = 'https://clever-it-hazel.vercel.app';

  Uri _buildUri(String path) {
    return Uri.parse('$_baseUrl$path');
  }

  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
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

    if ((operation == 'verifyPhoneOtp' || operation == 'signupUser') &&
        status == 401 &&
        (message == '$operation failed ($status)')) {
      message = 'Invalid or expired OTP. Please request a new OTP.';
    }

    if (operation == 'sendPhoneOtp' &&
        status == 429 &&
        (message == '$operation failed ($status)')) {
      message = 'Too many OTP requests. Please wait a minute and try again.';
    }

    debugPrint('AuthService $operation error: ${response.body}');
    throw Exception(message);
  }

  Exception _mapNetworkError(String operation, Object error) {
    final raw = error.toString().toLowerCase();
    debugPrint('AuthService $operation network error: $error');

    if (raw.contains('failed to fetch') ||
        raw.contains('xmlhttprequest') ||
        raw.contains('socketexception') ||
        raw.contains('connection')) {
      return Exception(
        'Cannot reach server. Check internet connection and backend availability.',
      );
    }
    return Exception(error.toString());
  }

  Future<bool> sendPhoneOtp(String phoneNumber) async {
    final uri = _buildUri('/api/auth/send-otp/');
    late final http.Response response;
    try {
      response = await http.post(
        uri,
        body: {'phone': phoneNumber},
      );
    } catch (e) {
      throw _mapNetworkError('sendPhoneOtp', e);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('sendPhoneOtp', response);
    }

    try {
      final body = jsonDecode(response.body);
      return body['userExists'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<VerifyOtpResult> verifyPhoneOtp(String phoneNumber, String otp) async {
    final uri = _buildUri('/api/auth/verify-otp/');
    late final http.Response response;
    try {
      response = await http.post(
        uri,
        body: {'phone': phoneNumber, 'otp': otp},
      );
    } catch (e) {
      throw _mapNetworkError('verifyPhoneOtp', e);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Catch the specific backend exception for unregistered users
      if (response.statusCode == 401 &&
          response.body.contains('ACCOUNT_NOT_FOUND_SIGNUP_REQUIRED')) {
        // Do nothing, let the code continue.
        // The parsing logic below will see token=null and mark isNewUser=true
      } else {
        _handleError('verifyPhoneOtp', response);
      }
    }

    Map<String, dynamic>? body;

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    }

    String? token;
    bool isNewUser;

    if (body != null) {
      final rawToken =
          body['access_token'] ??
          body['token'] ??
          body['accessToken'] ??
          body['authToken'];
      if (rawToken is String && rawToken.isNotEmpty) {
        token = rawToken;
      }

      final isNewUserField = body['isNewUser'];
      final isRegisteredField = body['isRegistered'];

      if (isNewUserField is bool) {
        isNewUser = isNewUserField;
      } else if (isRegisteredField is bool) {
        isNewUser = !isRegisteredField;
      } else {
        final hasToken = token != null && token.isNotEmpty;
        isNewUser = !hasToken;
      }
    } else {
      token = null;
      isNewUser = true;
    }

    if (token != null && !isNewUser) {
      await AuthService.saveAuthToken(token);
    }

    return VerifyOtpResult(isNewUser: isNewUser, token: token, data: body);
  }

  Future<void> signupUser({
    required String fullName,
    required String email,
    required String dateOfBirth,
    required String gender,
    required String phone,
    required String otp,
    required String street,
    required String city,
    required String state,
    required String pinCode,
  }) async {
    final uri = _buildUri('/api/auth/signup/');
    late final http.Response response;
    try {
      response = await http.post(
        uri,
        body: {
          'fullName': fullName.trim(),
          'email': email.trim(),
          'dateOfBirth': dateOfBirth.trim(),
          'gender': gender.trim(),
          'phone': phone.trim(),
          'otp': otp.trim(),
          'address[street]': street.trim(),
          'address[city]': city.trim(),
          'address[state]': state.trim(),
          'address[pinCode]': pinCode.trim(),
        },
      );
    } catch (e) {
      throw _mapNetworkError('signupUser', e);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('signupUser', response);
    }

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final rawToken =
              decoded['access_token'] ??
              decoded['token'] ??
              decoded['accessToken'] ??
              decoded['authToken'];
          if (rawToken is String && rawToken.isNotEmpty) {
            await AuthService.saveAuthToken(rawToken);
          }
        }
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = _buildUri('/api/auth/me');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('getProfile', response);
    }

    return jsonDecode(response.body);
  }

  Future<void> logout() async {
    final token = await getAuthToken();
    if (token == null) return;

    final uri = _buildUri('/api/auth/logout');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    await clearAuthToken();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError('logout', response);
    }
  }

  Future<void> sendOtp(String s) async {}
}

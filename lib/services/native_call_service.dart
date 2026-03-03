import 'package:flutter/services.dart';
import 'dart:async';

class NativeCallService {
  static const MethodChannel _channel = MethodChannel(
    'com.nighatech.pro_dialer/native_call',
  );

  static final NativeCallService _instance = NativeCallService._internal();
  factory NativeCallService() => _instance;

  NativeCallService._internal();

  Future<void> startCall(String phoneNumber) async {
    await _channel.invokeMethod('startCall', {'phoneNumber': phoneNumber});
  }
}

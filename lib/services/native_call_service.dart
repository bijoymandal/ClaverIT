import 'package:flutter/services.dart';
import 'dart:async';

class NativeCallService {
  static const MethodChannel _channel = MethodChannel(
    'com.nighatech.pro_dialer/native_call',
  );

  static final NativeCallService _instance = NativeCallService._internal();
  factory NativeCallService() => _instance;

  NativeCallService._internal();

  Future<int> getSimCount() async {
    final int simCount = await _channel.invokeMethod("getSimCount");
    return simCount;
  }

  Future<void> startCall(String phoneNumber, int simSlot) async {
    await _channel.invokeMethod('startCall', {
      'phoneNumber': phoneNumber,
      'simSlot': simSlot,
    });
  }
}

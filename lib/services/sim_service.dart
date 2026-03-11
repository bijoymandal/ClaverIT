import 'package:flutter/services.dart';

class SimService {
  // static const MethodChannel _channel = MethodChannel('sim_info');

  static const MethodChannel _channel = MethodChannel(
    'com.nighatech.pro_dialer/native_call',
  );
  static Future<List<String>> getSimProviders() async {
    final List sims = await _channel.invokeMethod('getSimProviders');
    return sims.map((e) => e.toString()).toList();
  }
}

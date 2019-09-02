import 'dart:async';

import 'package:flutter/services.dart';

class FlutterAdyen {
  static const MethodChannel _channel = const MethodChannel('flutter_adyen');

  static Future<String> get openDropIn async {
    Map<String, dynamic> args = {};
    args.putIfAbsent('paymentMethods', () => '{}');

    final String response = await _channel.invokeMethod('openDropIn', args);
    return response;
  }
}

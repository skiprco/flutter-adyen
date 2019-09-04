import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class FlutterAdyen {
  static const MethodChannel _channel = const MethodChannel('flutter_adyen');

  static Future<String> openDropIn({paymentMethods, baseUrl, authToken, merchantAccount, publicKey, amount, currency = 'EUR'}) async {
    Map<String, dynamic> args = {};
    args.putIfAbsent('paymentMethods', () => paymentMethods);
    args.putIfAbsent('baseUrl', () => baseUrl);
    args.putIfAbsent('authToken', () => authToken);
    args.putIfAbsent('merchantAccount', () => merchantAccount);
    args.putIfAbsent('pubKey', () => publicKey);
    args.putIfAbsent('amount', () => amount);
    args.putIfAbsent('currency', () => currency);

    final String response = await _channel.invokeMethod('openDropIn', args);
    return response;
  }
}
//
//var x = {
//  "paymentData": "",
//  "details": {
//    "payload": ""
//  }
//};

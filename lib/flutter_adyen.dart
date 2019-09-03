import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class FlutterAdyen {
  static const MethodChannel _channel = const MethodChannel('flutter_adyen');
  static var json = {
    "groups": [
      {
        "name": "Credit Card",
        "types": ["visa", "mc", "amex"]
      }
    ],
    "paymentMethods": [
      {
        "details": [
          {"key": "encryptedCardNumber", "type": "cardToken"},
          {"key": "encryptedSecurityCode", "type": "cardToken"},
          {"key": "encryptedExpiryMonth", "type": "cardToken"},
          {"key": "encryptedExpiryYear", "type": "cardToken"},
          {"key": "holderName", "optional": true, "type": "text"}
        ],
        "name": "Credit Card",
        "type": "scheme"
      },
      {"name": "Online bank transfer.", "supportsRecurring": true, "type": "directEbanking"},
      {"name": "Pay later with Klarna.", "supportsRecurring": true, "type": "klarna"},
      {"name": "Paysafecard", "supportsRecurring": true, "type": "paysafecard"},
      {
        "details": [
          {"key": "bic", "type": "text"}
        ],
        "name": "GiroPay",
        "supportsRecurring": true,
        "type": "giropay"
      },
      {"name": "Slice it with Klarna.", "supportsRecurring": true, "type": "klarna_account"}
    ]
  };

  static Future<String> get openDropIn async {
    Map<String, dynamic> args = {};
    args.putIfAbsent('paymentMethods', () => jsonEncode(json));
    args.putIfAbsent('baseUrl', () => jsonEncode(json));
    args.putIfAbsent('authToken', () => jsonEncode(json));
    args.putIfAbsent('merchantAccount', () => jsonEncode(json));

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

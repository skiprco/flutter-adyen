import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'dart:io' show Platform;

class FlutterAdyen {
  static const MethodChannel _channel = const MethodChannel('flutter_adyen');

  static Future<String> choosePaymentMethod({
    @required String paymentMethods,
    @required String urlPayments,
    @required String urlPaymentsDetails,
    String authToken,
    String iosReturnUrl,
    @required String merchantAccount,
    @required String publicKey,
    @required double amount,
    @required String currency,
    @required String reference,
    @required String shopperReference,
    @required bool allow3DS2,
    String httpMethod = 'POST',
    Map<String, String> headers,
    bool testEnvironment,
  }) async
  {
    assert(!(Platform.isIOS && iosReturnUrl == null));

    Map<String, dynamic> args = {};

    args.putIfAbsent('paymentMethods', () => paymentMethods);
    args.putIfAbsent('urlPayments', () => urlPayments);
    args.putIfAbsent('urlPaymentsDetails', () => urlPaymentsDetails);
    args.putIfAbsent('authToken', () => authToken);
    args.putIfAbsent('iosReturnUrl', () => iosReturnUrl);
    args.putIfAbsent('merchantAccount', () => merchantAccount);
    args.putIfAbsent('pubKey', () => publicKey);
    args.putIfAbsent('amount', () => amount);
    args.putIfAbsent('currency', () => currency);
    args.putIfAbsent('reference', () => reference);
    args.putIfAbsent('shopperReference', () => shopperReference);
    args.putIfAbsent('allow3DS2', () => allow3DS2);
    args.putIfAbsent('headers', () => shopperReference);
    args.putIfAbsent('httpMethod', () => httpMethod);
    args.putIfAbsent('testEnvironment', () => httpMethod);

    final String response = await _channel.invokeMethod('choosePaymentMethod', args);
    return response;
  }

  static Future<String> sendResponse(Map<String, dynamic> paymentCallResult) async {

    Map<String, dynamic> args = {};

    args.putIfAbsent('payload', () => json.encode(paymentCallResult));

    return await _channel.invokeMethod('onResponse', args);
  }
}

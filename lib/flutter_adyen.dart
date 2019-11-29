import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'dart:io' show Platform;

class FlutterAdyen {
  static const MethodChannel _channel = const MethodChannel('flutter_adyen');

  static Future<String> openDropIn({
    @required String paymentMethods,
    @required String urlPayments,
    @required String urlPaymentsDetails,
    @required String authToken,
    String iosReturnUrl,
    @required String merchantAccount,
    @required String publicKey,
    @required double amount,
    @required String currency,
    @required String reference,
    @required String shopperReference
    Map<String, String> headers
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

    final String response = await _channel.invokeMethod('openDropIn', args);
    return response;
  }
}

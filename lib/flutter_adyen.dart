import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'dart:io' show Platform;

class FlutterAdyen {
  static const MethodChannel _channel = const MethodChannel('flutter_adyen');

  static Future<String> choosePaymentMethod({
    @required String paymentMethodsPayload,
    String iosReturnUrl,
    @required String merchantAccount,
    @required String publicKey,
    @required double amount,
    @required String currency,
    @required String reference,
    @required String shopperReference,
    @required ShopperInteraction shopperInteraction,
    @required RecurringProcessingModels recurringProcessingModel,
    @required bool storePaymentMethod,
    @required bool allow3DS2,
    @required bool testEnvironment,
  }) async
  {
    assert(!(Platform.isIOS && iosReturnUrl == null));

    Map<String, dynamic> args = {};

    args.putIfAbsent('paymentMethodsPayload', () => paymentMethodsPayload);

    args.putIfAbsent('merchantAccount', () => merchantAccount);
    args.putIfAbsent('pubKey', () => publicKey);
    args.putIfAbsent('amount', () => amount);
    args.putIfAbsent('currency', () => currency);
    args.putIfAbsent('reference', () => reference);
    args.putIfAbsent('shopperReference', () => shopperReference);
    args.putIfAbsent('shopperInteraction', () => _enumToString(shopperInteraction));
    args.putIfAbsent('storePaymentMethod', () => storePaymentMethod);
    args.putIfAbsent('recurringProcessingModel', () => _enumToString(recurringProcessingModel));
    args.putIfAbsent('allow3DS2', () => allow3DS2);
    args.putIfAbsent('iosReturnUrl', () => iosReturnUrl);

    args.putIfAbsent('testEnvironment', () => testEnvironment);

    _log('choosePaymentMethod()');

    final String response = await _channel.invokeMethod('choosePaymentMethod', args);

    _log('choosePaymentMethod response $response');

    return response;
  }

  static Future<String> sendResponse(Map<String, dynamic> paymentCallResult) async {

    Map<String, dynamic> args = {};

    args.putIfAbsent('payload', () {
      var payload = json.encode(paymentCallResult);
      _log('payload $payload');
      return payload;
    });

    _log('onResponse()');

    final String response = await _channel.invokeMethod('onResponse', args);

    _log('onResponse response : $response');

    return response;
  }

  static Future<bool> clearStorage() async {
    if (Platform.isAndroid) {
      try {
        final String response = await _channel.invokeMethod('clearStorage');
        return response == 'SUCCESS';
      }on PlatformException catch (e) {
        debugPrint(e?.message);
        return false;
      }
    }
    return true;
  }
}

enum RecurringProcessingModels {
  /// A transaction for a fixed or variable amount, which follows a fixed schedule.
  Subscription,
  /// Card details are stored to enable one-click or omnichannel journeys, or simply to streamline the checkout process. Any subscription not following a fixed schedule is also considered a card-on-file transaction.
  CardOnFile,
  /// A transaction that occurs on a non-fixed schedule and/or have variable amounts. For example, automatic top-ups when a cardholder's balance drops below a certain amount.
  UnscheduledCardOnFile
}

enum ShopperInteraction {
  /// Online transactions where the cardholder is present (online). For better authorisation rates, we recommend sending the card security code (CSC) along with the request.
  Ecommerce,
  /// Card on file and/or subscription transactions, where the cardholder is known to the merchant (returning customer). If the shopper is present (online), you can supply also the CSC to improve authorisation (one-click payment).
  ContAuth,
  /// Mail-order and telephone-order transactions where the shopper is in contact with the merchant via email or telephone.
  Moto,
  /// Point-of-sale transactions where the shopper is physically present to make a payment using a secure payment terminal.
  POS
}

String _enumToString<T>(T enumValue, {String orElse()}) {
  var str = enumValue?.toString() ?? (orElse != null ? orElse() : null);
  if (str?.contains(".") ?? false) return str?.split('.')?.last ?? null;
  return str ?? null;
}

void _log(String toLog) {
  //print('ADYEN (flutter) : $toLog');
  //debugPrint('ADYEN (flutter) : $toLog');
} // print to logcat (to debug in release mode)
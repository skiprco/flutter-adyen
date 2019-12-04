import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adyen/flutter_adyen.dart';
import 'package:flutter_adyen_example/mock_data.dart' as prefix0;

import 'mock_data.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  String dropInResponse;

  Future<void> initPlatformState() async {
    if (!mounted) return;

    setState(() {
      _platformVersion = dropInResponse;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            try {
              dropInResponse = await FlutterAdyen.choosePaymentMethod(
                paymentMethods: jsonEncode(examplePaymentMethods),
                urlPayments: urlPayments,
                urlPaymentsDetails: urlPaymentsDetails,
                authToken: authToken,
                merchantAccount: merchantAccount,
                publicKey: pubKey,
                amount: 12.0,
                currency: 'EUR',
                iosReturnUrl: returnScheme + '://',
                reference: DateTime.now().millisecondsSinceEpoch.toString(),
                shopperReference: userID,
                allow3DS2: true
              );
            } on PlatformException {
              dropInResponse = 'Failed to get platform version.';
            }
            setState(() {
              _platformVersion = dropInResponse;
            });
            setState(() {});
          },
        ),
        appBar: AppBar(
          title: const Text('Flutter Adyen'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}

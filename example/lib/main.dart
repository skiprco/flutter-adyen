import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adyen/flutter_adyen.dart';

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

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
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
              dropInResponse = await FlutterAdyen.openDropIn(
                  paymentMethods: jsonEncode(examplePaymentMethods),
                  baseUrl: 'https://accounts-staging.i-atros.org',
                  authToken: 'Bearer ABCDEFGHIJKLMNOP', // Authorization header
                  merchantAccount: 'YOURMERCHANTACCOUNTCOM',
                  publicKey: pubKey,
                  amount: '103',
                  currency: 'EUR'
              );
            } on PlatformException {
              dropInResponse = 'Failed to get platform version.';
            }
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

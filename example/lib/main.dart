import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adyen/flutter_adyen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'mock_data.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _debugInfo = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  String? dropInResponse;

  Future<void> initPlatformState() async {
    if (!mounted) return;

    setState(() {
      _debugInfo = dropInResponse;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: SpeedDial(
          // both default to 16
          marginEnd: 18,
          marginBottom: 20,
          animatedIcon: AnimatedIcons.menu_close,
          animatedIconTheme: IconThemeData(size: 22.0),
          closeManually: false,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          //onOpen: () => print('OPENING DIAL'),
          //onClose: () => print('DIAL CLOSED'),
          tooltip: 'Speed Dial',
          heroTag: 'speed-dial-hero-tag',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 8.0,
          shape: CircleBorder(),
          children: [
            SpeedDialChild(
              child: Icon(Icons.delete),
              backgroundColor: Colors.red,
              label: 'clear',
              labelStyle: TextStyle(fontSize: 18.0),
              onTap: () => FlutterAdyen.clearStorage(),
            ),
            SpeedDialChild(
                child: Icon(Icons.directions_run),
                backgroundColor: Colors.blue,
                label: 'try flow',
                labelStyle: TextStyle(fontSize: 18.0),
                onTap: tryFlow
            ),
          ],
        ),
        appBar: AppBar(
          title: const Text('Flutter Adyen'),
        ),
        body: Center(
          child: Text('Don\'t forget the put a real pubKey in mock_data.dart\n'
              'Running on: $_debugInfo\n'),
        ),
      ),
    );
  }

  void tryFlow() async {
    var scheme = 'your_app://';
    var ref = "5933644c-ab32-49f7-a9cd-fd2dc87fab2e";
    var paymentMethodsPayload = json.encode(examplePaymentMethods);
    var userID = "abcdef";

    try {
      dropInResponse = await FlutterAdyen.choosePaymentMethod(
          paymentMethodsPayload: paymentMethodsPayload,
          merchantAccount: merchantAccount,
          publicKey: pubKey,
          amount: 12.0,
          currency: 'EUR',
          iosReturnUrl: scheme,
          reference: ref,
          shopperReference: userID,
          allow3DS2: true,
          testEnvironment: true,
          storePaymentMethod: false,
          showsStorePaymentMethodField: false,
          shopperInteraction: ShopperInteraction.ContAuth,
          recurringProcessingModel: RecurringProcessingModels.CardOnFile,
      );
    } on PlatformException catch (e){
      dropInResponse = 'PlatformException. ${e.message}';
    } on Exception {
      dropInResponse = 'Exception.';
    }

    setState(() {
      _debugInfo = dropInResponse;
    });

    var res = await FlutterAdyen.sendResponse(
        {
          "pspReference":"883577097894825J",
          "resultCode":"Authorised",
          "merchantReference":"e13e71f7-c9b7-406a-a800-18fce8204173"
        }
      /*{
              "resultCode": "RedirectShopper",
              "action": {
                "data": {
                  "MD": "OEVudmZVMUlkWjd0MDNwUWs2bmhSdz09...",
                  "PaReq": "eNpVUttygjAQ/RXbDyAXBYRZ00HpTH3wUosPfe...",
                  "TermUrl": "adyencheckout://your.package.name"
                },
                "method": "POST",
                "paymentData": "Ab02b4c0!BQABAgA4e3wGkhVah4CJL19qdegdmm9E...",
                "paymentMethodType": "scheme",
                "type": "redirect",
                "url": "https://test.adyen.com/hpp/3d/validate.shtml"
              },
              "details": [
                {
                  "key": "MD",
                  "type": "text"
                },
                {
                  "key": "PaRes",
                  "type": "text"
                }
              ],
            }*/
    );

    setState(() {
      _debugInfo = dropInResponse! + "||||" + res!;
    });
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class FlutterAdyen {
  static const MethodChannel _channel = const MethodChannel('flutter_adyen');
  static var json = {
    "groups": [
      {
        "name": "Credit Card",
        "types": ["amex", "bcmc", "cartebancaire", "mc", "visa", "visadankort"]
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
      {
        "details": [
          {"key": "encryptedCardNumber", "type": "cardToken"},
          {"key": "encryptedExpiryMonth", "type": "cardToken"},
          {"key": "encryptedExpiryYear", "type": "cardToken"},
          {"key": "holderName", "optional": true, "type": "text"}
        ],
        "name": "Bancontact card",
        "supportsRecurring": false,
        "type": "bcmc"
      },
      {"name": "Online bank transfer.", "supportsRecurring": true, "type": "directEbanking"},
      {
        "details": [
          {
            "items": [
              {"id": "231", "name": "POP Pankki"},
              {"id": "551", "name": "Komerční banka"},
              {"id": "232", "name": "Aktia"},
              {"id": "552", "name": "Raiffeisen"},
              {"id": "233", "name": "Säästöpankki"},
              {"id": "750", "name": "Swedbank"},
              {"id": "211", "name": "Nordea"},
              {"id": "553", "name": "ČSOB"},
              {"id": "234", "name": "S-Pankki"},
              {"id": "751", "name": "SEB"},
              {"id": "554", "name": "Moneta"},
              {"id": "235", "name": "OmaSP"},
              {"id": "752", "name": "Nordea"},
              {"id": "213", "name": "Op-Pohjola"},
              {"id": "555", "name": "UniCredit"},
              {"id": "753", "name": "LHV"},
              {"id": "556", "name": "Fio"},
              {"id": "557", "name": "mBank"},
              {"id": "216", "name": "Handelsbanken"},
              {"id": "558", "name": "Air Bank"},
              {"id": "260", "name": "Länsförsäkringar"},
              {"id": "240", "name": "BankDeposit"},
              {"id": "265", "name": "Sparbanken"},
              {"id": "640", "name": "BankDeposit"},
              {"id": "200", "name": "Ålandsbanken"},
              {"id": "940", "name": "Swedbank"},
              {"id": "500", "name": "Česká spořitelna"},
              {"id": "720", "name": "Swedbank"},
              {"id": "941", "name": "SEB"},
              {"id": "204", "name": "Danske Bank"},
              {"id": "721", "name": "SEB"},
              {"id": "942", "name": "Citadele"},
              {"id": "205", "name": "Handelsbanken"},
              {"id": "722", "name": "DNB"},
              {"id": "943", "name": "DNB"},
              {"id": "206", "name": "Nordea"},
              {"id": "723", "name": "Šiaulių bankas"},
              {"id": "207", "name": "SEB"},
              {"id": "724", "name": "Nordea"},
              {"id": "505", "name": "Komerční banka"},
              {"id": "208", "name": "Skandiabanken"},
              {"id": "209", "name": "Swedbank"}
            ],
            "key": "issuer",
            "type": "select"
          }
        ],
        "name": "Bank Payment",
        "supportsRecurring": true,
        "type": "entercash"
      },
      {
        "details": [
          {
            "items": [
              {"id": "d5d5b133-1c0d-4c08-b2be-3c9b116dc326", "name": "Dolomitenbank"},
              {"id": "ee9fc487-ebe0-486c-8101-17dce5141a67", "name": "Raiffeissen Bankengruppe"},
              {"id": "6765e225-a0dc-4481-9666-e26303d4f221", "name": "Hypo Tirol Bank AG"},
              {"id": "8b0bfeea-fbb0-4337-b3a1-0e25c0f060fc", "name": "Sparda Bank Wien"},
              {"id": "1190c4d1-b37a-487e-9355-e0a067f54a9f", "name": "Schoellerbank AG"},
              {"id": "e2e97aaa-de4c-4e18-9431-d99790773433", "name": "Volksbank Gruppe"},
              {"id": "bb7d223a-17d5-48af-a6ef-8a2bf5a4e5d9", "name": "Immo-Bank"},
              {"id": "e6819e7a-f663-414b-92ec-cf7c82d2f4e5", "name": "Bank Austria"},
              {"id": "eff103e6-843d-48b7-a6e6-fbd88f511b11", "name": "Easybank AG"},
              {"id": "25942cc9-617d-42a1-89ba-d1ab5a05770a", "name": "VR-BankBraunau"},
              {"id": "4a0a975b-0594-4b40-9068-39f77b3a91f9", "name": "Volkskreditbank"},
              {"id": "3fdc41fc-3d3d-4ee3-a1fe-cd79cfd58ea3", "name": "Erste Bank und Sparkassen"},
              {"id": "ba7199cc-f057-42f2-9856-2378abf21638", "name": "BAWAG P.S.K. Gruppe"}
            ],
            "key": "issuer",
            "type": "select"
          }
        ],
        "name": "EPS",
        "supportsRecurring": true,
        "type": "eps"
      },
      {
        "details": [
          {"key": "bic", "type": "text"}
        ],
        "name": "GiroPay",
        "supportsRecurring": true,
        "type": "giropay"
      },
      {
        "details": [
          {
            "items": [
              {"id": "1121", "name": "Test Issuer"},
              {"id": "1154", "name": "Test Issuer 5"},
              {"id": "1153", "name": "Test Issuer 4"},
              {"id": "1152", "name": "Test Issuer 3"},
              {"id": "1151", "name": "Test Issuer 2"},
              {"id": "1162", "name": "Test Issuer Cancelled"},
              {"id": "1161", "name": "Test Issuer Pending"},
              {"id": "1160", "name": "Test Issuer Refused"},
              {"id": "1159", "name": "Test Issuer 10"},
              {"id": "1158", "name": "Test Issuer 9"},
              {"id": "1157", "name": "Test Issuer 8"},
              {"id": "1156", "name": "Test Issuer 7"},
              {"id": "1155", "name": "Test Issuer 6"}
            ],
            "key": "issuer",
            "type": "select"
          }
        ],
        "name": "iDEAL",
        "supportsRecurring": true,
        "type": "ideal"
      },
      {"name": "Pay later with Klarna.", "supportsRecurring": true, "type": "klarna"},
      {"name": "Slice it with Klarna.", "supportsRecurring": true, "type": "klarna_account"},
      {"name": "Multibanco", "supportsRecurring": true, "type": "multibanco"},
      {"name": "Paysafecard", "supportsRecurring": true, "type": "paysafecard"},
      {"name": "Swish", "supportsRecurring": true, "type": "swish"}
    ]
  };

  static Future<String> get openDropIn async {
    Map<String, dynamic> args = {};
    args.putIfAbsent('paymentMethods', () => jsonEncode(json));

    final String response = await _channel.invokeMethod('openDropIn', args);
    return response;
  }
}

var examplePaymentMethods = {
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


String pubKey =
    '10001|AD931ED82E72912349C55B91880A967C7B9F816145DEEFA6F0589568CF7C589CE4F75AC06C833F28883C8AA1D5910405D0998D775C2E1A4F33CF6B307036A9A54B6635BA583D6F252865EFD5FFE98C1A301C26CB400A27F0844A18984A645BF9C987DF540B8C478334F943BE7739D294DEA852A85CA3FE6CF24E9E319C083AAEC89C578F593E06C0A96AD0F16FFB0C0F519F10CF089E67026B89411D29A2EC23CBA7188738352D3881430EA5C4866F0B8E8BEF84DF702B8D47BCFBA770638CC4FCB44B0285D9BB7FB2D9082AADBFB11DE3D63D3F99B74CD1621CB523224D9E16520BB6ED4F4A3ED31326D7B48878555DC3E65A48A284CA287909D6E3547D4E15';

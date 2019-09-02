# flutter_adyen

Flutter plugin to integrate with the Android and iOS libraries of Adyen.
This library enables you to open the Drop-in method of Adyen with just calling one function.

## Drop-in method

### Prerequisites

Before calling the plugin, make sure to get the *payment methods* from Adyen. For this, call the [a /paymentMethods](https://docs.adyen.com/api-explorer/#/PaymentSetupAndVerificationService/v46/paymentMethods) endpoint:


POST: https://checkout-test.adyen.com/v46/paymentMethods // Version number might be different
Payload should contain the merchant account
```
{
  "merchantAccount": "<YOUR ACCOUNT>"
}
```

Append your API key and a content-type to the headers:
```
Content-Type: application/json
X-API-KEY: AQEohm.......zyMjCt
```

Make sure to run this command from your backend. It's not recommended to store the API key in the front end!

### Calling the plugin
Pass the JSON to the plugin as a string.
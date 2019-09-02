package app.petleo.flutter_adyen

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class FlutterAdyenPlugin: MethodCallHandler {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "flutter_adyen")
      channel.setMethodCallHandler(FlutterAdyenPlugin())
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "openDropIn" -> {
//        val paymentMethods = call.argument<String>("paymentMethods")
//
//        try {
//          var gson = Gson()
//          var jsonObject = gson.toJson(paymentMethods);
//          val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(jsonObject)
//
//          result.success("Adyen:: Success. Response is: $paymentMethodsApiResponse")
//        } catch (e: Exception) {
//          result.success("Adyen:: Failed with this error: ${e.printStackTrace()}")
//        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }
}

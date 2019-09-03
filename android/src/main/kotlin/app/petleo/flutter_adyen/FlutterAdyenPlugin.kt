package app.petleo.flutter_adyen

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.preference.PreferenceManager
import android.util.Log
import com.adyen.checkout.base.model.PaymentMethodsApiResponse
import com.adyen.checkout.base.model.payments.Amount
import com.adyen.checkout.base.model.payments.request.*
import com.adyen.checkout.core.log.LogUtil
import com.adyen.checkout.core.log.Logger
import com.adyen.checkout.core.model.JsonUtils
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.DropInConfiguration
import com.adyen.checkout.dropin.service.CallResult
import com.adyen.checkout.dropin.service.DropInService
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.redirect.RedirectComponent
import com.google.gson.Gson
import com.squareup.moshi.Moshi
import com.squareup.moshi.adapters.PolymorphicJsonAdapterFactory
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import okhttp3.MediaType
import okhttp3.RequestBody
import org.json.JSONObject
import java.io.IOException


class FlutterAdyenPlugin(val activity: Activity, val channel: MethodChannel) : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_adyen")
            channel.setMethodCallHandler(FlutterAdyenPlugin(registrar.activity(), channel))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "openDropIn" -> {
                val paymentMethods = call.argument<String>("paymentMethods")

                try {
                    val gson = Gson()
                    Log.d("LOGGGGGG", gson.toJson(paymentMethods))
                    val jsonObject = JSONObject(paymentMethods)
                    val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(jsonObject)

                    val googlePayConfig = GooglePayConfiguration.Builder(activity, "TestMerchantCheckout").build()

                    val resultIntent = Intent(activity, activity::class.java)
                    resultIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP

                    val dropInConfiguration = DropInConfiguration.Builder(activity, resultIntent, MyDropInService::class.java)
                            .addGooglePayConfiguration(googlePayConfig)
                            .build()

                    DropIn.startPayment(activity, paymentMethodsApiResponse, dropInConfiguration)

                    result.success("Adyen:: Success. Response is: $paymentMethodsApiResponse")
                } catch (e: Throwable) {
                    result.success("Adyen:: Failed with this error: ${e.printStackTrace()}")
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}

/**
 * This is just an example on how to make network calls on the [DropInService].
 * You should make the calls to your own servers and have additional data or processing if necessary.
 */
class MyDropInService : DropInService() {

    companion object {
        private val TAG = LogUtil.getTag()
    }

    override fun makePaymentsCall(paymentComponentData: JSONObject): CallResult {
        Log.d("LOGGGGGG", "makePaymentsCall")
        Logger.d(TAG, "makePaymentsCall")

        // Check out the documentation of this method on the parent DropInService class

        Log.d("LOGGGGGG", "paymentComponentData - ${paymentComponentData.toString(JsonUtils.IDENT_SPACES)}")

        val serializedPaymentComponentData = PaymentComponentData.SERIALIZER.deserialize(paymentComponentData)

        if (serializedPaymentComponentData.paymentMethod == null) {
            return CallResult(CallResult.ResultType.ERROR, "Empty payment data")
        }

        val paymentsRequest = createPaymentsRequest(this@MyDropInService, serializedPaymentComponentData)
        val paymentsRequestJson = serializePaymentsRequest(paymentsRequest)
//
        Log.d("LOGGGGGG", "payments/ - ${paymentsRequestJson.toString(JsonUtils.IDENT_SPACES)}")
//
        val requestBody = RequestBody.create(MediaType.parse("application/json"), paymentsRequestJson.toString())

        val call = CheckoutApiService.INSTANCE.payments(requestBody)
        return try {
            val response = call.execute()
            val paymentsResponse = response.body()
            // Error body
            val byteArray = response.errorBody()?.bytes()
            if (byteArray != null) {
                Logger.e(TAG, "errorBody - ${String(byteArray)}")
            }
            if (response.isSuccessful && paymentsResponse != null) {
                if (paymentsResponse.paymentData != null) {
                    CallResult(CallResult.ResultType.ACTION, paymentsResponse.paymentData.toString())
                } else {
                    CallResult(CallResult.ResultType.FINISHED, paymentsResponse.resultCode
                            ?: "EMPTY")
                }
            } else {
                Log.d("LOGGGGGG", "FAILED - ${response.message()}")
                Log.d("LOGGGGGG", "FAILED - ${response.errorBody().toString()}")
                Log.d("LOGGGGGG", "FAILED - ${response.raw().request()}")
                Logger.e(TAG, "FAILED - ${response.message()}")
                CallResult(CallResult.ResultType.ERROR, "IOException")
            }
        } catch (e: IOException) {
            Log.e("LOGGGGGG", e.printStackTrace().toString())
            CallResult(CallResult.ResultType.ERROR, "IOException")
        }
    }

    override fun makeDetailsCall(actionComponentData: JSONObject): CallResult {
        Log.d("LOGGGGGG", "makeDetailsCall")
        Logger.d(TAG, "makeDetailsCall")
//
//        Logger.v(TAG, "payments/details/ - ${actionComponentData.toString(JsonUtils.IDENT_SPACES)}")
//
//        val requestBody = RequestBody.create(MediaType.parse("application/json"), actionComponentData.toString())
//        val call = CheckoutApiService.INSTANCE.details(requestBody)
//
//        return try {
//            val response = call.execute()
//            val detailsResponse = response.body()
//
//            if (response.isSuccessful && detailsResponse != null) {
//                if (detailsResponse.action != null) {
//                    CallResult(CallResult.ResultType.ACTION, Action.SERIALIZER.serialize(detailsResponse.action).toString())
//                } else {
//                    CallResult(CallResult.ResultType.FINISHED, detailsResponse.resultCode ?: "EMPTY")
//                }
//            } else {
//                Logger.e(TAG, "FAILED - ${response.message()}")
//                CallResult(CallResult.ResultType.ERROR, "IOException")
//            }
//        } catch (e: IOException) {
//            Logger.e(TAG, "IOException", e)
//            CallResult(CallResult.ResultType.ERROR, "IOException")
//        }
        return CallResult(CallResult.ResultType.FINISHED, "EMPTY")
    }
}


fun createPaymentsRequest(context: Context, paymentComponentData: PaymentComponentData<out PaymentMethodDetails>): PaymentsRequest {

    val preferences = PreferenceManager.getDefaultSharedPreferences(context)

    @Suppress("UsePropertyAccessSyntax")
    return PaymentsRequest(
            paymentComponentData.getPaymentMethod() as PaymentMethodDetails,
            paymentComponentData.getShopperReference() ?: "",
            paymentComponentData.isStorePaymentMethodEnable,
            getAmount(context, preferences), "IATROSGmbH700ECOM",
            RedirectComponent.getReturnUrl(context)
    )
}


private fun getAmount(context: Context, preferences: SharedPreferences): Amount {
    val amountValue = 1
    val amountCurrency = "EUR"
    return createAmount(amountValue, amountCurrency)
}

fun createAmount(value: Int, currency: String): Amount {
    val amount = Amount()
    amount.currency = currency
    amount.value = value
    return amount
}

data class PaymentsRequest(
        val paymentMethod: PaymentMethodDetails,
        val shopperReference: String,
        val storePaymentMethod: Boolean,
        val amount: Amount,
        val merchantAccount: String,
        // unique reference of the payment
        val returnUrl: String,
        val reference: String = "android-test-components",
        val channel: String = "android",
        val additionalData: AdditionalData = AdditionalData(allow3DS2 = "false")
)

data class AdditionalData(val allow3DS2: String = "false")

private fun serializePaymentsRequest(paymentsRequest: PaymentsRequest): JSONObject {
    val moshi = Moshi.Builder()
            .add(PolymorphicJsonAdapterFactory.of(PaymentMethodDetails::class.java, PaymentMethodDetails.TYPE)
                    .withSubtype(CardPaymentMethod::class.java, CardPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(IdealPaymentMethod::class.java, IdealPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(MolpayPaymentMethod::class.java, MolpayPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(EPSPaymentMethod::class.java, EPSPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(DotpayPaymentMethod::class.java, DotpayPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(EntercashPaymentMethod::class.java, EntercashPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(OpenBankingPaymentMethod::class.java, OpenBankingPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(GooglePayPaymentMethod::class.java, GooglePayPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(GenericPaymentMethod::class.java, "other")
            )
            .build()
    val jsonAdapter = moshi.adapter(PaymentsRequest::class.java)
    val requestString = jsonAdapter.toJson(paymentsRequest)
    val request = JSONObject(requestString)

    // TODO GooglePayPaymentMethod token has a variable name that is not compatible with Moshi
    request.remove("paymentMethod")
    request.put("paymentMethod", PaymentMethodDetails.SERIALIZER.serialize(paymentsRequest.paymentMethod))

    return request
}
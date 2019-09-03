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
import com.adyen.checkout.base.model.payments.response.Action
import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.core.log.LogUtil
import com.adyen.checkout.core.log.Logger
import com.adyen.checkout.core.model.JsonUtils
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.DropInConfiguration
import com.adyen.checkout.dropin.service.CallResult
import com.adyen.checkout.dropin.service.DropInService
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.redirect.RedirectComponent
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
                val baseUrl = call.argument<String>("baseUrl")
                val authToken = call.argument<String>("authToken")
                val merchantAccount = call.argument<String>("merchantAccount")
                val pubKey = call.argument<String>("pubKey")

                try {
                    val jsonObject = JSONObject(paymentMethods)
                    val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(jsonObject)

                    val googlePayConfig = GooglePayConfiguration.Builder(activity, merchantAccount
                            ?: "").build()
                    val cardConfiguration = CardConfiguration.Builder(activity, pubKey
                            ?: "").build()

                    val resultIntent = Intent(activity, activity::class.java)
                    resultIntent.putExtra("BaseUrl", baseUrl)
                    resultIntent.putExtra("Authorization", authToken)

                    val sharedPref = activity.getSharedPreferences("ADYEN", Context.MODE_PRIVATE)
                    with(sharedPref.edit()) {
                        putString("Authorization", "Bearer BULENTANDPATRICKCOMPLAINSALOT")
                        commit()
                    }
                    resultIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP

                    val dropInConfiguration = DropInConfiguration.Builder(activity, resultIntent, MyDropInService::class.java)
                            .addCardConfiguration(cardConfiguration)
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

        val sharedPref = getSharedPreferences("ADYEN", Context.MODE_PRIVATE)
        Log.d("PREFFSSSSSS", sharedPref.getString("Authorization", "UNDEFINED_STR"))
        Log.d("PREFFSSSSSS", sharedPref.getString("BaseUrl", "UNDEFINED_STR"))

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

        val headers: HashMap<String, String> = HashMap()
        val call = getService(headers).payments(requestBody)
        call.request().headers()
        return try {
            val response = call.execute()
            val paymentsResponse = response.body()

            Log.d("LOGGGGGG - 1 ", response.toString())
            // Error body
            val byteArray = response.errorBody()?.bytes()
            if (byteArray != null) {
                Log.d("LOGGGGGG", "errorBody - ${String(byteArray)}")
            }
            Log.d("LOGGGGGG", " 4")
            if (response.isSuccessful && paymentsResponse != null) {
                Log.d("LOGGGGGG", " 5")
                if (paymentsResponse.action != null) {
                    CallResult(CallResult.ResultType.ACTION, Action.SERIALIZER.serialize(paymentsResponse.action).toString())
                } else {
                    Log.d("LOGGGGGG", " 7")
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
        Log.d("LOGGGGGG", "makeDetailsCall")

        Log.d("LOGGGGGG", "payments/details/ - ${actionComponentData.toString(JsonUtils.IDENT_SPACES)}")

        val requestBody = RequestBody.create(MediaType.parse("application/json"), actionComponentData.toString())
        val call = getService(HashMap()).details(requestBody)

        return try {
            Log.d("LOGGGGGG", "try")
            val response = call.execute()
            val detailsResponse = response.body()
            Log.d("LOGGGGGG", "try 2")

            if (response.isSuccessful && detailsResponse != null) {
                Log.d("LOGGGGGG", "try 3 ${detailsResponse.resultCode}")
                Log.d("LOGGGGGG", "try 3 res =  $response")
                Log.d("LOGGGGGG", "try 3 ${detailsResponse.paymentData}")
                if (detailsResponse.resultCode != null && detailsResponse.resultCode == "Authorised") {
                    CallResult(CallResult.ResultType.ACTION, detailsResponse.resultCode)
                } else {
                    Log.d("LOGGGGGG", "try 5")
                    CallResult(CallResult.ResultType.FINISHED, detailsResponse.resultCode
                            ?: "EMPTY")
                }
            } else {
                Log.d("LOGGGGGG", "try 6")
                Logger.e(TAG, "FAILED - ${response.message()}")
                CallResult(CallResult.ResultType.ERROR, "IOException")
            }
        } catch (e: IOException) {
            Logger.e(TAG, "IOException", e)
            CallResult(CallResult.ResultType.ERROR, "IOException")
        }
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
    val amountValue = 245
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
    Log.d("LOGGGGGGG", "serializePaymentsRequest started")

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

    request.remove("paymentMethod")
    request.put("paymentMethod", PaymentMethodDetails.SERIALIZER.serialize(paymentsRequest.paymentMethod))

    Log.d("LOGGGGGGG", "serializePaymentsRequest done")
    return request
}
package app.petleo.flutter_adyen

import android.app.Activity
import android.content.Context
import android.content.Intent
//import android.os.Environment
import com.adyen.checkout.base.model.PaymentMethodsApiResponse
import com.adyen.checkout.base.model.payments.Amount
import com.adyen.checkout.base.model.payments.request.*
import com.adyen.checkout.base.model.payments.response.Action
import com.adyen.checkout.bcmc.BcmcConfiguration
import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.core.api.Environment
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
import org.json.JSONObject
import kotlin.math.roundToInt
import com.adyen.checkout.bcmc.BcmcComponentProvider as BcmcComponentProvider

var result: Result? = null
var mActivity: Activity? = null

const val sharedPrefsKey:String = "ADYEN"

class FlutterAdyenPlugin(private val activity: Activity) : MethodCallHandler {

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_adyen")
            channel.setMethodCallHandler(FlutterAdyenPlugin(registrar.activity()))
        }
    }

    override fun onMethodCall(call: MethodCall, res: Result) {
        when (call.method) {
            "choosePaymentMethod" -> choosePaymentMethod(call, res)
            "onResponse" -> onResponse(call, res)
            else -> res.notImplemented()
        }
    }

    private fun choosePaymentMethod(call: MethodCall, res: Result) {
        val paymentMethodsPayload = call.argument<String>("paymentMethodsPayload")

        val merchantAccount = call.argument<String>("merchantAccount")
        val pubKey = call.argument<String>("pubKey")
        val amount = call.argument<Double>("amount")
        val currency = call.argument<String>("currency")
        val reference = call.argument<String>("reference")
        val shopperReference = call.argument<String>("shopperReference")
        val storePaymentMethod = call.argument<Boolean>("storePaymentMethod") ?: false
        val allow3DS2 = call.argument<Boolean>("allow3DS2") ?: false
        val testEnvironment = call.argument<Boolean>("testEnvironment") ?: false

        try {
            val jsonObject = JSONObject(paymentMethodsPayload?: "")
            val paymentMethodsPayloadString = PaymentMethodsApiResponse.SERIALIZER.deserialize(jsonObject)
            val googlePayConfig = GooglePayConfiguration.Builder(activity, merchantAccount?: "").build()
            val cardConfiguration = CardConfiguration.Builder(activity, pubKey?: "").build()
            val bcmcConfiguration = BcmcConfiguration.Builder(activity, pubKey?:"").build()
            val resultIntent = Intent(activity, activity::class.java)

            val sharedPref = activity.getSharedPreferences(sharedPrefsKey, Context.MODE_PRIVATE)
            with(sharedPref.edit()) {
                putString("merchantAccount", merchantAccount)
                putString("amount", amount.toString())
                putString("currency", currency)
                putString("channel", "Android")
                putString("reference", reference)
                putString("shopperReference", shopperReference)
                putBoolean("storePaymentMethod", storePaymentMethod)
                putBoolean("allow3DS2", allow3DS2)
                commit()
            }
            resultIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP

            val dropInConfig = DropInConfiguration.Builder(activity, resultIntent, MyDropInService::class.java)
                    .addCardConfiguration(cardConfiguration)
                    .addGooglePayConfiguration(googlePayConfig)
                    .addBcmcConfiguration(bcmcConfiguration)

            if (testEnvironment)
                dropInConfig.setEnvironment(Environment.TEST)
            else
                dropInConfig.setEnvironment(Environment.EUROPE)

            val dropInConfiguration = dropInConfig.build()

            DropIn.startPayment(activity, paymentMethodsPayloadString, dropInConfiguration)
            result = res
            mActivity = activity
        } catch (e: Throwable) {
            res.error("Adyen:: Failed with this error: ", "${e.printStackTrace()}", "")
        }
    }

    private fun onResponse(call: MethodCall, res: Result) {
        result = res;

        val payload = call.argument<String>("payload")
        val data = JSONObject(payload!!)

        MyDropInService.instance.finish(data)
    }
}

class MyDropInService : DropInService() {

    companion object {
        lateinit var instance: MyDropInService
        //private val TAG = LogUtil.getTag()
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }


    override fun makePaymentsCall(paymentComponentData: JSONObject): CallResult {
        val sharedPref = getSharedPreferences(sharedPrefsKey, Context.MODE_PRIVATE)

        val merchantAccount = sharedPref.getString("merchantAccount", "UNDEFINED_STR")
        val amount = sharedPref.getString("amount", "UNDEFINED_STR")
        val currency = sharedPref.getString("currency", "UNDEFINED_STR")
        val reference = sharedPref.getString("reference", "UNDEFINED_STR")
        val shopperReference = sharedPref.getString("shopperReference", "UNDEFINED_STR")
        val allow3DS2 = sharedPref.getBoolean("allow3DS2", false)

        val serializedPaymentComponentData = PaymentComponentData.SERIALIZER.deserialize(paymentComponentData)

        if (serializedPaymentComponentData.paymentMethod == null)
            return CallResult(CallResult.ResultType.ERROR, "Empty payment data")

        val paymentsRequestBody = createPaymentsRequest(
            this@MyDropInService,
            serializedPaymentComponentData,
            amount ?: "",
            currency ?: "",
            merchantAccount ?: "",
            reference,
            shopperReference,
            allow3DS2 = allow3DS2
        )
        val paymentsRequestBodyJson = serializePaymentsRequest(paymentsRequestBody)

        val resp = paymentsRequestBodyJson.toString()

        mActivity?.runOnUiThread { result?.success(resp) }

        return CallResult(CallResult.ResultType.FINISHED, resp)
    }

    override fun makeDetailsCall(actionComponentData: JSONObject): CallResult {
        /*
        val sharedPref = getSharedPreferences(sharedPrefsKey, Context.MODE_PRIVATE)
        val requestBody = RequestBody.create(MediaType.parse("application/json"), actionComponentData.toString())
        headers["Authorization"] = authorization ?: ""
        val call = getService(headers, baseUrl ?: "").details(requestBody)
        return try {
            val response = call.execute()
            val detailsResponse = response.body()

            if (response.isSuccessful && detailsResponse != null) {
                if (detailsResponse.resultCode != null &&
                        (detailsResponse.resultCode == "Authorised" || detailsResponse.resultCode == "Received" || detailsResponse.resultCode == "Pending")) {
                    mActivity?.runOnUiThread { result?.success("SUCCESS") }
                    return CallResult(CallResult.ResultType.FINISHED, detailsResponse.resultCode)
                } else {
                    mActivity?.runOnUiThread { result?.error("Result code is ${detailsResponse.resultCode}", "Payment not Authorised", "") }
                    return CallResult(CallResult.ResultType.FINISHED, detailsResponse.resultCode
                            ?: "EMPTY")
                }
            } else {
                mActivity?.runOnUiThread { result?.error("FAILED - ${response.message()}", "IOException", "") }
                return CallResult(CallResult.ResultType.ERROR, "IOException")
            }
        } catch (e: IOException) {
            mActivity?.runOnUiThread { result?.error("FAILED", e.stackTrace.toString(), "") }
            return CallResult(CallResult.ResultType.ERROR, "IOException")
        }
        */
        return CallResult(CallResult.ResultType.FINISHED, "")
    }

    fun finish(paymentsResponse: JSONObject): CallResult {
        if (paymentsResponse.has("action")) {
            val action = paymentsResponse.getString("action")
            return CallResult(CallResult.ResultType.ACTION, /*Action.SERIALIZER.serialize(*/action/*).toString()*/)
        } else {
            val code = paymentsResponse.getString("resultCode")
            if (code == "Authorised" ||
                code == "Received" ||
                code == "Pending"
            ){
                mActivity?.runOnUiThread { result?.success("SUCCESS") }
                return CallResult(CallResult.ResultType.FINISHED, code)
            } else {
                mActivity?.runOnUiThread { result?.error("Result code is ${code}", "Payment not Authorised", "") }
                return CallResult(CallResult.ResultType.FINISHED, code?: "EMPTY")
            }
        }
    }
}


fun createPaymentsRequest(context: Context,
                          paymentComponentData: PaymentComponentData<out PaymentMethodDetails>,
                          amount: String,
                          currency: String,
                          merchant: String,
                          reference: String?,
                          shopperReference: String?,
                          allow3DS2: Boolean
): PaymentsRequest {
    @Suppress("UsePropertyAccessSyntax")
    return PaymentsRequest(
            paymentComponentData.getPaymentMethod() as PaymentMethodDetails,
            paymentComponentData.isStorePaymentMethodEnable,
            shopperReference ?: "NO_REFERENCE_DEFINED",
            getAmount(amount, currency),
            merchant,
            RedirectComponent.getReturnUrl(context),
            reference ?: "",
            additionalData = AdditionalData(allow3DS2 = allow3DS2.toString())
    )
}

private fun getAmount(amount: String, currency: String) = createAmount(amount, currency)

fun createAmount(value: String, currency: String): Amount {
    val amount = Amount()
    amount.currency = currency
    amount.value = value.toInt()
    return amount
}

data class PaymentsRequest(
    val paymentMethod: PaymentMethodDetails,
    val storePaymentMethod: Boolean,
    val shopperReference: String,
    val amount: Amount,
    val merchantAccount: String,
    val returnUrl: String,
    val reference: String,
    val channel: String = "android",
    val additionalData: AdditionalData = AdditionalData(allow3DS2 = "false")
)

data class AdditionalData(val allow3DS2: String = "false")

private fun serializePaymentsRequest(paymentsRequest: PaymentsRequest): JSONObject {
    val moshi = Moshi.Builder()
            .add(PolymorphicJsonAdapterFactory.of(PaymentMethodDetails::class.java, PaymentMethodDetails.TYPE)
                    .withSubtype(CardPaymentMethod::class.java, CardPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(IdealPaymentMethod::class.java, IdealPaymentMethod.PAYMENT_METHOD_TYPE)
                    //.withSubtype(MolpayPaymentMethod::class.java, MolpayPaymentMethod.PAYMENT_METHOD_TYPE)
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
    return request
}
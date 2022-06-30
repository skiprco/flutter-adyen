package app.petleo.flutter_adyen

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
import com.adyen.checkout.bcmc.BcmcConfiguration
import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.components.model.PaymentMethodsApiResponse
import com.adyen.checkout.components.model.payments.Amount
import com.adyen.checkout.components.model.payments.request.*
import com.adyen.checkout.components.util.PaymentMethodTypes
import com.adyen.checkout.core.api.Environment
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.DropInConfiguration
import com.adyen.checkout.dropin.service.DropInService
import com.adyen.checkout.dropin.service.DropInServiceResult
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

var result: Result? = null
var mActivity: Activity? = null

const val sharedPrefsKey:String = "ADYEN"

const val enableLogging = false;

class FlutterAdyenPlugin(private val activity: Activity) : MethodCallHandler {

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_adyen")
            channel.setMethodCallHandler(FlutterAdyenPlugin(registrar.activity()!!))
        }
    }

    override fun onMethodCall(call: MethodCall, res: Result) {
        when (call.method) {
            "choosePaymentMethod" -> choosePaymentMethod(call, res)
            "onResponse" -> onResponse(call, res)
            "clearStorage" -> onClearStorageRequested(call, res)
            else -> res.notImplemented()
        }
    }

    private fun onClearStorageRequested(call: MethodCall, res: Result) {
        val sharedPref = activity.getSharedPreferences(sharedPrefsKey, Context.MODE_PRIVATE)
        sharedPref.edit().clear().apply()
        activity?.runOnUiThread { res?.success("SUCCESS") }
    }

    private fun choosePaymentMethod(call: MethodCall, res: Result) {
        log("choosePaymentMethod")
        val paymentMethodsPayload = call.argument<String>("paymentMethodsPayload")

        val merchantAccount = call.argument<String>("merchantAccount")
        val pubKey = call.argument<String>("pubKey")
        val amount = call.argument<Double>("amount")
        val currency = call.argument<String>("currency")
        val reference = call.argument<String>("reference")
        val shopperReference = call.argument<String>("shopperReference")
        val storePaymentMethod = call.argument<Boolean>("storePaymentMethod") ?: false
        val shopperInteraction = call.argument<String>("shopperInteraction")
        val recurringProcessingModel = call.argument<String>("recurringProcessingModel")
        val allow3DS2 = call.argument<Boolean>("allow3DS2") ?: false

        val testEnvironment = call.argument<Boolean>("testEnvironment") ?: false
        val showsStorePaymentMethodField = call.argument<Boolean>("showsStorePaymentMethodField") ?: false

        try {
            val jsonObject = JSONObject(paymentMethodsPayload?: "")
            val paymentMethodsPayloadString = PaymentMethodsApiResponse.SERIALIZER.deserialize(jsonObject)
            log("paymentMethodsPayloadString $paymentMethodsPayloadString")
            val googlePayConfig = GooglePayConfiguration.Builder(activity, pubKey?: "").build()
            val cardConfiguration = CardConfiguration.Builder(activity, pubKey?: "")
                    .setShowStorePaymentField(showsStorePaymentMethodField)
                    .build()
            val bcmcConfiguration = BcmcConfiguration.Builder(activity, pubKey?:"").build()

            val resultIntent = Intent(activity, activity::class.java)
            resultIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP

            //TODO : don't store all this, dart version already has all of them
            val sharedPref = activity.getSharedPreferences(sharedPrefsKey, Context.MODE_PRIVATE)
            with(sharedPref.edit()) {
                putString("merchantAccount", merchantAccount)
                putString("amount", amount.toString())
                putString("currency", currency)
                putString("channel", "Android")
                putString("reference", reference)
                putString("shopperReference", shopperReference)
                putBoolean("storePaymentMethod", storePaymentMethod)
                putString("shopperInteraction", shopperInteraction)
                putString("recurringProcessingModel", recurringProcessingModel)
                putBoolean("allow3DS2", allow3DS2)
                commit()
            }

            val dropInConfig = DropInConfiguration.Builder(activity, MyDropInService::class.java, pubKey?: "")
                //.setAmount(Amount())
                .setEnvironment(if (testEnvironment) Environment.TEST else Environment.EUROPE)
                //.setShopperLocale()
                .addCardConfiguration(cardConfiguration)
                .addGooglePayConfiguration(googlePayConfig)
                .addBcmcConfiguration(bcmcConfiguration)

            val dropInConfiguration = dropInConfig.build()

            log("opening dropin")

            DropIn.startPayment(activity, paymentMethodsPayloadString, dropInConfiguration)

            result = res
            mActivity = activity
        } catch (e: Throwable) {
            log("dropin startpayment error")
            res.error("Error", "Adyen:: Failed with this error: ${e.printStackTrace()}", null)
        }
    }

    private fun onResponse(call: MethodCall, res: Result) {
        result = res

        log ("onresponse")

        val payload = call.argument<String>("payload")
        val data = JSONObject(payload!!)

        log ("dropin finish")

        MyDropInService.instance.finish(data)

        log ("dropin finished")
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


    override fun makePaymentsCall(paymentComponentData: JSONObject): DropInServiceResult {
        log ("make payments call")

        val sharedPref = getSharedPreferences(sharedPrefsKey, Context.MODE_PRIVATE)

        val merchantAccount = sharedPref.getString("merchantAccount", "UNDEFINED_STR")
        val amount = sharedPref.getString("amount", "UNDEFINED_STR")
        val currency = sharedPref.getString("currency", "UNDEFINED_STR")
        val reference = sharedPref.getString("reference", "UNDEFINED_STR")
        val shopperReference = sharedPref.getString("shopperReference", "UNDEFINED_STR")
        val shopperInteraction = sharedPref.getString("shopperInteraction", "UNDEFINED_STR")
        val storePaymentMethod = sharedPref.getBoolean("storePaymentMethod", false)
        val recurringProcessingModel = sharedPref.getString("recurringProcessingModel", "UNDEFINED_STR")
        val allow3DS2 = sharedPref.getBoolean("allow3DS2", false)

        val serializedPaymentComponentData = PaymentComponentData.SERIALIZER.deserialize(paymentComponentData)

        if (serializedPaymentComponentData.paymentMethod == null)
            return DropInServiceResult.Error("Empty payment data")

        log ("before create payment request")

        val paymentsRequestBody = createPaymentsRequest(
            this@MyDropInService,
            serializedPaymentComponentData,
            amount ?: "",
            currency ?: "",
            merchantAccount ?: "",
            reference,
            shopperReference,
            allow3DS2,
            shopperInteraction ?: "",
            recurringProcessingModel ?: ""
        )
        val paymentsRequestBodyJson = serializePaymentsRequest(paymentsRequestBody)

        log ("payment request : ${paymentsRequestBodyJson}")

        val resp = paymentsRequestBodyJson.toString()

        mActivity?.runOnUiThread { result?.success(resp) }

        return DropInServiceResult.Finished(resp)
    }

    override fun makeDetailsCall(actionComponentData: JSONObject): DropInServiceResult {
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
        return DropInServiceResult.Finished("")
    }

    //TODO move this logic to the dart side, it's the same on ios
    fun finish(paymentsResponse: JSONObject): DropInServiceResult {
        if (paymentsResponse.has("action")) {
            log("finish : action")
            val action = paymentsResponse.getString("action")
            return DropInServiceResult.Action(action)
        } else {
            log("finish : no action")
            val code = paymentsResponse.getString("resultCode")
            log("finish : code:$code")
            if (code == "Authorised" ||
                code == "Received" ||
                code == "Pending"
            ){
                log("finish : result code ${code}")
                mActivity?.runOnUiThread { result?.success("SUCCESS") }
                return DropInServiceResult.Finished(code)
            } else {
                log("finish : error")
                mActivity?.runOnUiThread { result?.error(code, "Payment not Authorised", null) }
                return DropInServiceResult.Finished(code?: "EMPTY")
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
                          allow3DS2: Boolean,
                          shopperInteraction: String,
                          recurringProcessingModel: String
): PaymentsRequest {
    @Suppress("UsePropertyAccessSyntax")
    return PaymentsRequest(
            paymentComponentData.getPaymentMethod() as PaymentMethodDetails,
            paymentComponentData.isStorePaymentMethodEnable,
            shopperReference ?: "NO_REFERENCE_DEFINED",
            shopperInteraction,
            recurringProcessingModel,
            getAmount(amount, currency),
            merchant,
            RedirectComponent.getReturnUrl(context),
            reference ?: "",
            "android",
            additionalData = AdditionalData(allow3DS2 = allow3DS2)
    )
}

private fun getAmount(amount: String, currency: String) = createAmount(amount, currency)

fun createAmount(value: String, currency: String): Amount {
    log("createAmount < $value $currency")
    val amount = Amount()
    amount.currency = currency
    amount.value = value.toDouble().roundToInt()
    log("createAmount > ${amount.value} ${amount.currency}")
    return amount
}

data class PaymentsRequest(
    val paymentMethod: PaymentMethodDetails,
    val storePaymentMethod: Boolean,
    val shopperReference: String,
    val shopperInteraction: String,
    val recurringProcessingModel: String,
    val amount: Amount,
    val merchantAccount: String,
    val returnUrl: String,
    val reference: String,
    val channel: String,
    val additionalData: AdditionalData = AdditionalData(allow3DS2 = false)
)

data class AdditionalData(val allow3DS2: Boolean = false)

private fun serializePaymentsRequest(paymentsRequest: PaymentsRequest): JSONObject {
    log("serializePaymentsRequest")

    val moshi = Moshi.Builder()
            .add(PolymorphicJsonAdapterFactory.of(PaymentMethodDetails::class.java, PaymentMethodDetails.TYPE)
                    .withSubtype(CardPaymentMethod::class.java, CardPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(IdealPaymentMethod::class.java, IdealPaymentMethod.PAYMENT_METHOD_TYPE)
                    //.withSubtype(MolpayPaymentMethod::class.java, MolpayPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(EPSPaymentMethod::class.java, EPSPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(DotpayPaymentMethod::class.java, DotpayPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(EntercashPaymentMethod::class.java, EntercashPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(OpenBankingPaymentMethod::class.java, OpenBankingPaymentMethod.PAYMENT_METHOD_TYPE)
                    .withSubtype(GooglePayPaymentMethod::class.java, PaymentMethodTypes.GOOGLE_PAY) // GooglePayPaymentMethod.PAYMENT_METHOD_TYPE)
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

private fun log(toLog: String) {
    @Suppress("ConstantConditionIf")
    if (enableLogging)
        Log.d(sharedPrefsKey, "ADYEN (native) : $toLog")
}

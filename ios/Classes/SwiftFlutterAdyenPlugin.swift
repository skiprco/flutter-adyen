import Flutter
import UIKit
import Adyen
import Adyen3DS2
import Foundation

public class SwiftFlutterAdyenPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_adyen", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterAdyenPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    var dropInComponent: DropInComponent?
    
    var merchantAccount: String = ""
    var pubKey: String = ""
    var amount: Double = 0.0
    var currency: String = ""
    var returnUrl: String?
    var shopperReference: String = ""
    var reference: String = ""
    var allow3DS2: Bool = false
    var testEnvironment: Bool = false
    var shopperInteraction:String = ""
    var storePaymentMethod: Bool = false
    var recurringProcessingModel:String = ""
    var mResult: FlutterResult?
    var topController: UIViewController?
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "choosePaymentMethod":
            choosePaymentMethod(call, result: result)
        case "onResponse":
            onResponse(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
        
    private func choosePaymentMethod(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        mResult = result
        
        let arguments = call.arguments as? [String: Any]
        let paymentMethodsPayload = arguments?["paymentMethodsPayload"] as? String
        
        merchantAccount = arguments?["merchantAccount"] as! String
        pubKey = arguments?["pubKey"] as! String
        amount = arguments?["amount"] as! Double
        currency = arguments?["currency"] as! String
        returnUrl = arguments?["iosReturnUrl"] as? String
        shopperReference = arguments?["shopperReference"] as! String
        shopperInteraction = arguments?["shopperInteraction"] as! String
        storePaymentMethod = arguments?["storePaymentMethod"] as! Bool
        let showsStorePaymentMethodField = arguments?["showsStorePaymentMethodField"] as! Bool
        recurringProcessingModel = arguments?["recurringProcessingModel"] as! String
        reference = arguments?["reference"] as! String
        allow3DS2 = arguments?["allow3DS2"] as! Bool
        testEnvironment = arguments?["testEnvironment"] as? Bool ?? false
        
        guard let paymentData = paymentMethodsPayload?.data(using: .utf8),
            let paymentMethods = try? JSONDecoder().decode(PaymentMethods.self, from: paymentData) else {
                return
        }
        
        let apiContext = APIContext(environment: testEnvironment ? Environment.test : Environment.live, clientKey: pubKey)
        
        let configuration = DropInComponent.Configuration(apiContext: apiContext)
        configuration.card.showsStorePaymentMethodField = showsStorePaymentMethodField
        
        dropInComponent = DropInComponent(paymentMethods: paymentMethods, configuration: configuration)
        dropInComponent?.delegate = self
        
        //        topController = UIApplication.shared.keyWindow?.rootViewController
        //        while let presentedViewController = topController?.presentedViewController {
        //            topController = presentedViewController
        //        }
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            self.topController = topController
            while let presentedViewController = topController.presentedViewController{
                topController = presentedViewController
            }
            
            if #available(iOS 13.0, *) {
                dropInComponent!.viewController.overrideUserInterfaceStyle = .light
            }
            
            topController.present(dropInComponent!.viewController, animated: true)
        }
    }
    
    private func onResponse(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        mResult = result
        
        let arguments = call.arguments as? [String: Any]
        let payload = arguments?["payload"] as! String
        let data = payload.data(using: .utf8)!

        finish(data: data, component: dropInComponent!)
    }
}

extension SwiftFlutterAdyenPlugin: DropInComponentDelegate {
    // back from the ui, for payment call
    public func didSubmit(_ data: PaymentComponentData, for paymentMethod: PaymentMethod, from component: DropInComponent) {
        
        guard let paymentMethodEncoded = try? JSONEncoder().encode(data.paymentMethod.encodable) else { return }

        guard let paymentMethodJson = try? JSONSerialization.jsonObject(with: paymentMethodEncoded) else { return }
                                
        // prepare json data
        let json: [String: Any] = [
           "paymentMethod": paymentMethodJson,
           "amount": [
            "currency": currency,
            "value": amount
           ],
           "channel": "iOS",
           "merchantAccount": merchantAccount,
           "reference": reference,
           "returnUrl": returnUrl!,
           "shopperReference": shopperReference,
           "storePaymentMethod": storePaymentMethod,
           "shopperInteraction": shopperInteraction,
           "recurringProcessingModel": recurringProcessingModel,
           "additionalData": [
               "allow3DS2": allow3DS2
           ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else { return }
                
        let convertedString = String(data: jsonData, encoding: .utf8)

        self.mResult!(convertedString)

        return
    }
    
    // called when details are needed (3DSecure?)
    public func didProvide(_ data: ActionComponentData, from component: DropInComponent) {
        /* TODO
        guard let url = URL(string: urlPaymentsDetails) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if (authToken != nil) {
            request.setValue("\(authToken!)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json: [String: Any] = ["details": data.details.dictionaryRepresentation,"paymentData": data.paymentData]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if(data != nil) {
                self.finish(data: data!, component: component)
            }
        }.resume()*/
    }
    
    public func didFail(with error: Error, from component: DropInComponent) {
        // if error description contains error 0, return "CLOSED" instead of "CANCELLED"
        if error.localizedDescription.contains("error 0") {
            self.mResult!("CLOSED")
        } else {
            self.mResult!("CANCELLED")
        }
        dismissAdyenController()
    }
    
    fileprivate func dismissAdyenController() {
        DispatchQueue.global(qos: .background).async {
            // Background Thread
            DispatchQueue.main.async {
                self.topController?.dismiss(animated: false, completion: nil)
            }
        }
    }

    public func didComplete(from component: DropInComponent) {
        //TODO
    }

    private func finish(data: Data, component: DropInComponent) {
        let paymentResponseJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
        if let paymentResponseJson = paymentResponseJson as? Dictionary<String,Any> {
            let action = paymentResponseJson["action"]
            if(action != nil) {
                let act = try? JSONDecoder().decode(Action.self, from: JSONSerialization.data(withJSONObject: action!))
                if(act != nil){
                    component.handle(act!)
                }
            } else {
                let resultCode = paymentResponseJson["resultCode"] as? String
                let success = resultCode == "Authorised" || resultCode == "Received" || resultCode == "Pending"
                //component.stopLoading()
                if (success) {
                    self.mResult!("SUCCESS")
                    dismissAdyenController()
                } else {
                    let err = FlutterError(code: resultCode ?? "", message: "Failed with result code \(String(describing: resultCode ?? "-none-"))", details: nil)
                    self.mResult!(err)
                    dismissAdyenController()
                }
            }
        }
    }
}

extension UIViewController: PaymentComponentDelegate {
    
    public func didSubmit(_ data: PaymentComponentData, from component: PaymentComponent) {
        //performPayment(with: public  }
    }
    
    public func didFail(with error: Error, from component: PaymentComponent) {
        //performPayment(with: public  }
    }
    
}

extension UIViewController: ActionComponentDelegate {
    public func didComplete(from component: ActionComponent) {
        //
    }
    
    public func didFail(with error: Error, from component: ActionComponent) {
        //performPayment(with: public  }
    }
    
    public func didProvide(_ data: ActionComponentData, from component: ActionComponent) {
        //performPayment(with: public  }
    }
    
}

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
    var currency: String = ""
    var amount: Double = 0.0
    var returnUrl: String?
    var shopperReference: String = ""
    var reference: String = ""
    var allow3DS2: Bool = false
    var testEnvironment: Bool = false

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
        
    public func choosePaymentMethod(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        let paymentMethodsPayload = arguments?["paymentMethodsPayload"] as? String
        
        merchantAccount = arguments?["merchantAccount"] as! String
        pubKey = arguments?["pubKey"] as! String
        currency = arguments?["currency"] as! String
        amount = arguments?["amount"] as! Double
        returnUrl = arguments?["iosReturnUrl"] as? String
        shopperReference = arguments?["shopperReference"] as! String
        reference = arguments?["reference"] as! String
        allow3DS2 = arguments?["allow3DS2"] as! Bool
        testEnvironment = arguments?["testEnvironment"] as? Bool ?? false
        
        mResult = result
        
        guard let paymentData = paymentMethodsPayload?.data(using: .utf8),
            let paymentMethods = try? JSONDecoder().decode(PaymentMethods.self, from: paymentData) else {
                return
        }
        
        let configuration = DropInComponent.PaymentMethodsConfiguration()
        configuration.card.publicKey = pubKey
        dropInComponent = DropInComponent(paymentMethods: paymentMethods, paymentMethodsConfiguration: configuration)
        dropInComponent?.delegate = self
        dropInComponent?.environment = testEnvironment ? .test : .live
        
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
    
    public func onResponse(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        let payload = arguments?["payload"] as! String
        let data = payload.data(using: .utf8)!
        /*
         do{
             if let json = stringToParse.data(using: String.Encoding.utf8){
                 if let jsonData = try JSONSerialization.jsonObject(with: json, options: .allowFragments) as? [String:AnyObject]{

                     let id = jsonData["id"] as! String

                     ...
                 }
             }
         }catch {
             print(error.localizedDescription)

         }
         */
        
        finish(data: data, component: dropInComponent!)
    }
}

extension SwiftFlutterAdyenPlugin: DropInComponentDelegate {
    
    public func didSubmit(_ data: PaymentComponentData, from component: DropInComponent) {
        //guard let url = URL(string: urlPayments) else { return }
        
        // prepare json data
        let json: [String: Any] = [
           "paymentMethod": data.paymentMethod.dictionaryRepresentation,
           "amount": [
            "currency": currency,
            "value": amount
           ],
           "channel": "iOS",
           "merchantAccount": merchantAccount,
           "reference": reference,
           "returnUrl": returnUrl!,
           "storePaymentMethod": data.storePaymentMethod,
           "additionalData": [
            "allow3DS2": allow3DS2
           ]
        ]

        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        do {
            let convertedString = String(data: jsonData!, encoding: String.Encoding.utf8)
            print(convertedString ?? "defaultvalue")
            self.mResult!(convertedString)
        } catch let myJSONError {
            print(myJSONError)
            self.mResult!(FlutterError(code: "1", message: myJSONError.localizedDescription, details: nil))
        }
        
        return
    }
        
    fileprivate func dismissAdyenController() {
        DispatchQueue.global(qos: .background).async {
            // Background Thread
            DispatchQueue.main.async {
                self.topController?.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    func finish(data: Data, component: DropInComponent) {
        let paymentResponseJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String,Any>
        if ((paymentResponseJson) != nil) {
            let action = paymentResponseJson?!["action"]
            if(action != nil) {
                let act = try? JSONDecoder().decode(Action.self, from: JSONSerialization.data(withJSONObject: action!))
                if(act != nil){
                    component.handle(act!)
                }
            } else {
                let resultCode = try? paymentResponseJson!!["resultCode"] as? String
                let success = resultCode == "Authorised" || resultCode == "Received" || resultCode == "Pending"
                component.stopLoading()
                if (success) {
                    self.mResult!("SUCCESS")
                    dismissAdyenController()
                } else {
                    let err = FlutterError(code: "2", message: "Failed with result code \(String(describing: resultCode ?? "-none-"))", details: nil)
                    self.mResult!(err)
                    dismissAdyenController()
                }
            }
        }
    }
    
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
       self.mResult!("CANCELLED")
       dismissAdyenController()
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
    
    public func didFail(with error: Error, from component: ActionComponent) {
        //performPayment(with: public  }
    }
    
    public func didProvide(_ data: ActionComponentData, from component: ActionComponent) {
        //performPayment(with: public  }
    }
    
}

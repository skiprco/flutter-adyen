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
    
    var urlPayments: String
    var urlPaymentsDetails: String
    var authToken: String?
    var merchantAccount: String
    var pubKey: String
    var currency: String
    var amount: String
    var returnUrl: String?
    var shopperReference: String
    var reference: String
    var allow3DS2: Bool
    var httpMethod: String
    var testEnvironment: Bool

    var mResult: FlutterResult?
    var topController: UIViewController?
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method.elementsEqual("openDropIn") else { return }
        
        let arguments = call.arguments as? [String: Any]
        let paymentMethodsResponse = arguments?["paymentMethods"] as? String
        
        urlPayments = arguments?["urlPayments"] as! String
        urlPaymentsDetails = arguments?["urlPaymentsDetails"] as! String
        authToken = arguments?["authToken"] as? String
        merchantAccount = arguments?["merchantAccount"] as! String
        pubKey = arguments?["pubKey"] as! String
        currency = arguments?["currency"] as! String
        amount = arguments?["amount"] as! String
        returnUrl = arguments?["iosReturnUrl"] as? String
        shopperReference = arguments?["shopperReference"] as! String
        reference = arguments?["reference"] as! String
        allow3DS2 = arguments?["allow3DS2"] as! Bool
        httpMethod = arguments?["httpMethod"] as? String ?? "POST"
        testEnvironment = arguments?["testEnvironment"] as! Bool
        
        mResult = result
        
        guard let paymentData = paymentMethodsResponse?.data(using: .utf8),
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
            topController.present(dropInComponent!.viewController, animated: true)
        }
    }
}

extension SwiftFlutterAdyenPlugin: DropInComponentDelegate {
    
    public func didSubmit(_ data: PaymentComponentData, from component: DropInComponent) {
        guard let url = URL(string: urlPayments) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        if (authToken != nil){
            request.setValue("\(authToken!)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //TODO loop through headers
        //request.addValue(<#T##value: String##String#>, forHTTPHeaderField: <#T##String#>)
        
        // prepare json data
        let json: [String: Any] = [
           "paymentMethod": data.paymentMethod.dictionaryRepresentation,
           "amount": [
            "currency": currency,
            "value": Double(amount)!
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
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        request.httpBody = jsonData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if(data != nil) {
                self.finish(data: data!, component: component)
            }
            }.resume()
    }
    
    func finish(data: Data, component: DropInComponent) {
        let paymentResponseJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String,Any>
        if ((paymentResponseJson) != nil) {
            let action = paymentResponseJson?!["action"]
            if(action != nil) {
                let act = try? JSONDecoder().decode(Action.self, from: JSONSerialization.data(withJSONObject: action)) as! Action
                if(act != nil){
                    component.handle(act!)
                }
            } else {
                let resultCode = try? paymentResponseJson!!["resultCode"] as! String
                let success = resultCode == "Authorised" || resultCode == "Received" || resultCode == "Pending"
                component.stopLoading()
                if (success) {
                    self.mResult!("SUCCESS")
                    DispatchQueue.global(qos: .background).async {
                        
                        // Background Thread
                        DispatchQueue.main.async {
                            self.topController?.dismiss(animated: false, completion: nil)
                        }
                    }
                } else {
                    self.mResult!("Failed with result code \(resultCode)")
                    DispatchQueue.global(qos: .background).async {
                        
                        // Background Thread
                        
                        DispatchQueue.main.async {
                            self.topController?.dismiss(animated: false, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    public func didProvide(_ data: ActionComponentData, from component: DropInComponent) {
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
            }.resume()
    }
    
    public func didFail(with error: Error, from component: DropInComponent) {
       self.mResult!("CANCELLED")
       DispatchQueue.global(qos: .background).async {
            
            // Background Thread
            
            DispatchQueue.main.async {
                self.topController?.dismiss(animated: false, completion: nil)
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
    
    public func didFail(with error: Error, from component: ActionComponent) {
        //performPayment(with: public  }
    }
    
    public func didProvide(_ data: ActionComponentData, from component: ActionComponent) {
        //performPayment(with: public  }
    }
    
}

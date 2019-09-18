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
    var baseURL: String?
    var authToken: String?
    var merchantAccount: String?
    var pubKey: String?
    var currency: String?
    var amount: String?
    var shopperReference: String?
    var reference: String?
    var mResult: FlutterResult?

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method.elementsEqual("openDropIn") else { return }

        let arguments = call.arguments as? [String: Any]
        let paymentMethodsResponse = arguments?["paymentMethods"] as? String
        baseURL = arguments?["baseUrl"] as? String
        authToken = arguments?["authToken"] as? String
        merchantAccount = arguments?["merchantAccount"] as? String
        pubKey = arguments?["pubKey"] as? String
        currency = arguments?["currency"] as? String
        amount = arguments?["amount"] as? String
        shopperReference = arguments?["shopperReference"] as? String
        reference = arguments?["reference"] as? String
        mResult = result

        guard let paymentData = paymentMethodsResponse?.data(using: .utf8),
            let paymentMethods = try? JSONDecoder().decode(PaymentMethods.self, from: paymentData) else {
            return
        }

        let configuration = DropInComponent.PaymentMethodsConfiguration()
        configuration.card.publicKey = pubKey
        dropInComponent = DropInComponent(paymentMethods: paymentMethods, paymentMethodsConfiguration: configuration)
        dropInComponent?.delegate = self
        dropInComponent?.environment = .test

        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.present(dropInComponent!.viewController, animated: true)
        }
    }
}

extension SwiftFlutterAdyenPlugin: DropInComponentDelegate {
    
    public func didSubmit(_ data: PaymentComponentData, from component: DropInComponent) {
        guard let baseURL = baseURL, let url = URL(string: baseURL + "payments/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(authToken!)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let amountAsDouble = Double(amount!)
        // prepare json data
        let json: [String: Any] = ["paymentMethod": data.paymentMethod.dictionaryRepresentation,
                                   "amount": ["currency":currency, "value":amountAsDouble],
                                   "channel": "iOS",
                                   "merchantAccount": merchantAccount,
                                   "reference": reference,
                                   "returnUrl": "iATROS://",
                                   "storePaymentMethod": false,
                                   "additionalData": ["allow3DS2":"false"]]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        request.httpBody = jsonData
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("RESPONSE IS  ", response)
            print("ERROR IS  ",error)
            if(data != nil) {
                self.finish(data: data!, component: component)
            }
        }.resume()
    }

    func finish(data: Data, component: DropInComponent) {
        print("ACT IS FINSH CALLED")
        let decodedString = String(data: data, encoding: .utf8)!
        let paymentResponseJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String,Any>
        if((paymentResponseJson) != nil) {
            let action = paymentResponseJson?!["action"]
                  let act = try? JSONDecoder().decode(Action.self, from: JSONSerialization.data(withJSONObject: action, options: .fragmentsAllowed)) as! Action
            print("ACT IS ", act)
                  if(act != nil){
                      component.handle(act!)
                  } else {
                    print("ACT IS 1 ")
                      let resultCode = try? paymentResponseJson!!["resultCode"] as! String
                    print("ACT IS RESULTCODE ", resultCode)
                      let success = resultCode == "Authorised" || resultCode == "Received" || resultCode == "Pending"
                        component.stopLoading()
                        if (success) {
                            self.mResult!("SUCCESS")
                        } else {
                            self.mResult!("Failed with result code \(resultCode)")
                        }
                  }
        }
    }
    
    public func didProvide(_ data: ActionComponentData, from component: DropInComponent) {
        print("FUCKING BULENT")
         guard let baseURL = baseURL, let url = URL(string: baseURL + "payments/details/") else { return }
               var request = URLRequest(url: url)
               request.httpMethod = "POST"
               request.setValue("\(authToken!)", forHTTPHeaderField: "Authorization")
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
        print("FUCKING JUNUS")
        
        //performPayment(with: public  }
    }
}

extension UIViewController: PaymentComponentDelegate {

    public func didSubmit(_ data: PaymentComponentData, from component: PaymentComponent) {
        print("FUCKING JULIAN")
        //performPayment(with: public  }
    }

    public func didFail(with error: Error, from component: PaymentComponent) {
        print("FUCKING CERI")
        //performPayment(with: public  }
    }

}

extension UIViewController: ActionComponentDelegate {

    public func didFail(with error: Error, from component: ActionComponent) {
        print("FUCKING PATRICK")
        //performPayment(with: public  }
    }

    public func didProvide(_ data: ActionComponentData, from component: ActionComponent) {
        print("FUCKING SHAWKY")
        //performPayment(with: public  }
    }

}

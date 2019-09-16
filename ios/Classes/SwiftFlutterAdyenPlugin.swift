import Flutter
import UIKit
import Adyen
import Adyen3DS2

public class SwiftFlutterAdyenPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_adyen", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterAdyenPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    var dropInComponent: DropInComponent?
    var baseURL: String?
    var authToken: Int?
    var merchantAccount: Int?
    var pubKey: Int?
    var currency: String?
    var shopperReference: String?
    var reference: String?

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method.elementsEqual("openDropIn") else { return }

        let arguments = call.arguments as? [String: Any]
        let paymentMethodsResponse = arguments?["paymentMethods"] as? String
        baseURL = arguments?["baseUrl"] as? String
        authToken = arguments?["authToken"] as? Int
        merchantAccount = arguments?["merchantAccount"] as? Int
        pubKey = arguments?["pubKey"] as? Int
        currency = arguments?["currency"] as? String
        shopperReference = arguments?["shopperReference"] as? String
        reference = arguments?["reference"] as? String

        guard let paymentData = paymentMethodsResponse?.data(using: .utf8),
            let paymentMethods = try? JSONDecoder().decode(PaymentMethods.self, from: paymentData) else {
            return
        }

        let configuration = DropInComponent.PaymentMethodsConfiguration()
        configuration.card.publicKey = "10001|AD931ED82E72912349C55B91880A967C7B9F816145DEEFA6F0589568CF7C589CE4F75AC06C833F28883C8AA1D5910405D0998D775C2E1A4F33CF6B307036A9A54B6635BA583D6F252865EFD5FFE98C1A301C26CB400A27F0844A18984A645BF9C987DF540B8C478334F943BE7739D294DEA852A85CA3FE6CF24E9E319C083AAEC89C578F593E06C0A96AD0F16FFB0C0F519F10CF089E67026B89411D29A2EC23CBA7188738352D3881430EA5C4866F0B8E8BEF84DF702B8D47BCFBA770638CC4FCB44B0285D9BB7FB2D9082AADBFB11DE3D63D3F99B74CD1621CB523224D9E16520BB6ED4F4A3ED31326D7B48878555DC3E65A48A284CA287909D6E3547D4E15" // Your public key, retrieved from the Customer Area.
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
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            print(data)
            print(response)
            print(error)
        }.resume()
    }

    public func didProvide(_ data: ActionComponentData, from component: DropInComponent) {
        print("FUCKING BULENT")
        //performPayment(with: public  }
    }

    public func didFail(with error: Error, from component: DropInComponent) {
        print("FUCKING JUNUS")
        //performPayment(with: public  }
    }
}

//extension UIViewController: PaymentComponentDelegate {
//
//    public func didSubmit(_ data: PaymentComponentData, from component: PaymentComponent) {
//        print("FUCKING JULIAN")
//        //performPayment(with: public  }
//    }
//
//    public func didFail(with error: Error, from component: PaymentComponent) {
//        print("FUCKING CERI")
//        //performPayment(with: public  }
//    }
//
//}
//
//extension UIViewController: ActionComponentDelegate {
//
//    public func didFail(with error: Error, from component: ActionComponent) {
//        print("FUCKING PATRICK")
//        //performPayment(with: public  }
//    }
//
//    public func didProvide(_ data: ActionComponentData, from component: ActionComponent) {
//        print("FUCKING SHAWKY")
//        //performPayment(with: public  }
//    }
//
//}


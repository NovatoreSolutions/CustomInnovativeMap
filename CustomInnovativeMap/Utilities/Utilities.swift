//
//  Utils.swift
//  ANA
//
//  Created by Novatore-iOS on 24/02/2017.
//  Copyright © 2017 Novatore Solutions. All rights reserved.
//

import Foundation

class Global {
    
    static var isInternetOffline = false
    static var isSignedIn = false
    static var isGuest = false
    static var invoiceProductArray = [Product]()
    static var userPackage = Package()
    static let MaxOrders = 3
    static let MaxNoOfProducts = 10
    
    
    static func turnOffOnSliderPanGesture(panGestureOff: Bool) {
        SlideMenuOptions.panGesturesEnabled = panGestureOff
    }
    
    static func showBlackStatusBar() {
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    static func showWhiteStatusBar() {
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    static func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "^(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?(?:(?:(?:[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+(?:\\.[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+)*)|(?:\"(?:(?:(?:(?: )*(?:(?:[!#-Z^-~]|\\[|\\])|(?:\\\\(?:\\t|[ -~]))))+(?: )*)|(?: )+)\"))(?:@)(?:(?:(?:[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)(?:\\.[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)*)|(?:\\[(?:(?:(?:(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))\\.){3}(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))))|(?:(?:(?: )*[!-Z^-~])*(?: )*)|(?:[Vv][0-9A-Fa-f]+\\.[-A-Za-z0-9._~!$&'()*+,;=:]+))\\])))(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?$"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: testStr)
        return result
    }
    
    
    static func isValidName(_ testStr:String) -> Bool {
        let myCharSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let output = testStr.trimmingCharacters(in: myCharSet.inverted)
        let isValid = (testStr == output)
        
        return isValid
    }
    
    static func isValidNumber(testNum:String) -> Bool{
        if(testNum.characters.count == Constants.numberDigits){   // 13 for pak  12 for Qatar
            return true
        }
        else{
            return false
        }
        
    }
    
    static func alertAction(title: String, message: String) -> UIAlertController {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle:UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel)
        { action -> Void in
            
        })
        return alertController
    }
    
    static func alertActionWithoutOK(title: String, message: String) -> UIAlertController {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle:UIAlertControllerStyle.alert)
        
        return alertController
    }
    
    static func storeUserInfoInUserDefaults(authToken: String, cellNumber: String, email: String, name: String, user_id: Int) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "session")
        defaults.set("\(authToken)", forKey: "authKey")
        defaults.set("\(cellNumber)", forKey: "cellNumber")
        defaults.set("\(email)", forKey: "email")
        defaults.set("\(name)", forKey: "name")
        defaults.set(user_id, forKey: "user_id")
        defaults.synchronize()
        print("hello \(String(describing: defaults.value(forKey: "name")))")
    }
    
    
    
}

extension NSMutableString {
    
    func sha256() -> String{
        if let stringData = self.data(using: String.Encoding.utf8.rawValue) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }
    
    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
    
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: forState)
    }
}

extension String {
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: Data(utf8), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            print(error)
            return nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

extension UIImage {
    func save(fileName: String, type: String) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        if type.lowercased() == "png" {
            let path = URL(string: "\(documentsPath)/\(fileName).\(type)")
            try! UIImagePNGRepresentation(self)?.write(to: path!, options: .atomicWrite)
        } else if type.lowercased() == "jpg" {
            let path = URL(string: "\(documentsPath)/\(fileName).\(type)")
            try! UIImageJPEGRepresentation(self, 1.0)?.write(to: path!, options: .atomicWrite)
        } else {
            
        }
    }
    
    convenience init?(fileName: String, type: String) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let path = "\(documentsPath)\(fileName).\(type)"
        self.init(contentsOfFile: path)
    }
}

}


//
//  Constants.swift
//  AnaProject
//
//  Created by AMK on 28/03/2017.
//  Copyright © 2017 AMK. All rights reserved.
//

import UIKit
import Photos

class Constants: NSObject {
    
    static let countryCode = "+92"  // +974
    static let rangeOfNumbers = 2  //3 for QATAR //2 for Pak
    static let numberDigits = 13  // 12 for QATAR //13 for Pak
    
    let selectedColor = UIColor(red:92.0/255.0, green: 58.0/255.0, blue: 75.0/255.0, alpha:1.0)
    let viewColor = UIColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha:1.0)
    let lineUnselectedColor = UIColor(red: 196.0/255.0, green: 178.0/255.0, blue: 187.0/255.0, alpha:1.0)
    let transferManager = AWSS3TransferManager.default()
    
    static var progressView: UIProgressView = UIProgressView()
    
    func setRegularFont(Size:Float)-> UIFont{
        
        return UIFont(name:"Ubuntu",size:CGFloat(Size))!
        
    }
    
    func setBoldFont(Size:Float)-> UIFont{
        
        return UIFont(name:"Ubuntu-Bold",size:CGFloat(Size))!
        
    }
    
    func setCellFont(Size:Float)-> UIFont{
        
        return UIFont(name:"Ubuntu-B.ttf",size:CGFloat(Size))!
        
    }
    
    func setNavigationTitle(title:String)-> UILabel{
        
        let label = UILabel()
        label.textAlignment = NSTextAlignment.left
        label.text = title
        return label
        
    }
    
    func setBorderColor(button:Any) {
        
        (button as AnyObject).layer.cornerRadius = 2
        (button as AnyObject).layer.shadowColor = UIColor .black.cgColor
        (button as AnyObject).layer.shadowOffset = CGSize(width:0.0, height:3.0); //Here your control your spread
        (button as AnyObject).layer.shadowOpacity = 0.5
        (button as AnyObject).layer.shadowRadius = 2.0   //Here you control the blur
        (button as AnyObject).layer.cornerRadius = 4.0
        
    }
    
    func setFloatingLabel(textField: B68UIFloatLabelTextField, isCenterAlign: Bool) {
        
        if isCenterAlign {
            textField.horizontalFloatingLabel = (textField.frame.size.width - textField.floatingLabel.frame.size.width)/2
        }
        else {
            textField.horizontalFloatingLabel = 0
        }
        let border = CALayer()
        let width = CGFloat(0.5)
        border.borderColor = UIColor.darkGray.cgColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width: textField.frame.size.width+100, height: textField.frame.size.height)
        
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
        
    }
    
    static func showLoader()
    {
        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.custom)
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.black)
        SVProgressHUD.setRingThickness(3)
        SVProgressHUD.setRingRadius(0.1)
        SVProgressHUD.show()
    }
    
    
    static func hideLoader()
    {
        SVProgressHUD.dismiss()
    }
    
    func getInvoiceImagePath(info: [String: AnyObject]) -> URL {
        
        let fileName = self.getImageName(info: info)
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let imagePath = documentsPath?.appendingPathComponent(fileName)
        
        // extract image from the picker and save it
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            try! UIImageJPEGRepresentation(pickedImage, 0.0)?.write(to: imagePath!)
        }
        return imagePath!
        
    }
    
    func randomAlphaNumericString(length: Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let allowedCharsCount = UInt32(allowedChars.characters.count)
        var randomString = ""
        
        for _ in 0..<length {
            let randomNum = Int(arc4random_uniform(allowedCharsCount))
            let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
            let newCharacter = allowedChars[randomIndex]
            randomString += String(newCharacter)
        }
        return randomString
    }
    
}



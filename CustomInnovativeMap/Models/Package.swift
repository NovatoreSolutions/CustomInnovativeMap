//
//  Pacakge.swift
//  ANA
//
//  Created by Novatore-iOS on 17/03/2017.
//  Copyright © 2017 Novatore Solutions. All rights reserved.
//

import Foundation

class Package {
    
    var locationObject: ToFromLocationDetails?
    var recipient: Receipient?
    var packageQuantity: PackageQuantity?
    var packageInstructions:String?
    var date: DateSlots?
    var time: TimeSlots?
    var trackingInfo: TrackingInfo?
    var senderDetail: SenderDetail?
    var InvoiceProductList: [Product] = []
    var packageID:String?
    
    var packageAmount:Int = 0
    var packageTotal:Int = 0
    
    var isSelfRecipient: Bool?
    var isSender: Bool?
    var isReceiver: Bool?
    
    init(locationObject: ToFromLocationDetails) {
        self.locationObject = locationObject
    }
    
    func getProductsTotal() -> Int {
        if (InvoiceProductList.count) != nil {
            if (InvoiceProductList.count) > 0 {
                var totalProductSum = 0
                if (InvoiceProductList.count) != nil {
                    for i in 0..<(InvoiceProductList.count) {
                        totalProductSum = totalProductSum + (InvoiceProductList[i].totalPrice)!
                    }
                    return Int(sum)
                }
                else {
                    return 0
                }
            }
            else {
                if packageTotal != 0 {
                    return Int(packageTotal)
                }
                else {
                    return 0
                }
            }
        }
        else {
            if packageTotal != 0 {
                return Int(packageTotal)
            }
            else {
                return 0
            }
        }
    }
}

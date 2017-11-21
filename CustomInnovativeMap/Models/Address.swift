//
//  Address.swift
//  google maps
//
//  Created by macbookpro on 16/03/2017.
//  Copyright © 2017 macbookpro. All rights reserved.
//

import Foundation

class Address {
    var fromAddress: String?
    var toAddress: String?
    
    init(fromAddress: String, toAddress: String) {
        self.fromAddress = fromAddress
        self.toAddress = toAddress
    }
}

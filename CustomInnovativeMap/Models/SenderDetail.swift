//
//  SenderDetail.swift
//  ANA
//
//  Created by Novatore-iOS on 11/04/2017.
//  Copyright © 2017 Novatore Solutions. All rights reserved.
//

import Foundation

class SenderDetail:NSObject {
    var senderName: String?
    var senderEmail: String?
    var senderCell: String?
    var senderPassword: String?
    var senderId: Int?
    var isGuest = false //for Guest User Type
    
    
    init?(name: String, email: String, cellNo: String) {
        
        // Initialization should fail if there is no name or no cell number
        if name.isEmpty || cellNo.isEmpty {
            return nil
        }
        
        // Initialize stored properties
        self.senderName = name
        self.senderEmail = email
        self.senderCell = cellNo
    }

}

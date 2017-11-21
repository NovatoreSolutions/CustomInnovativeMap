
//
//  Receipient.swift
//  ANA
//
//  Created by Novatore-iOS on 17/03/2017.
//  Copyright © 2017 Novatore Solutions. All rights reserved.
//

import Foundation

class Receipient:NSObject {
    
    //MARK: Properties
    var name:String!
    var email:String!
    var cellNo:String!
    
    //MARK: Initialization
    init?(name: String, email: String, cellNo: String) {
        
        // Initialization should fail if there is no name or no cell number
        if name.isEmpty || cellNo.isEmpty {
            return nil
        }
        
        // Initialize stored properties
        self.name = name
        self.email = email
        self.cellNo = cellNo
    }
}

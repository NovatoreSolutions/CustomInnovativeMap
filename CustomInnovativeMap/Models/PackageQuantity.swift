//
//  PackageQuantity.swift
//  ANA
//
//  Created by Novatore-iOS on 17/03/2017.
//  Copyright © 2017 Novatore Solutions. All rights reserved.
//

import Foundation

class PackageQuantity {
    
    var smallQuantity: Int?
    var mediumQuantity: Int?
    var largeQuantity: Int?
    
    //MARK: Initialization
    init(smallQuantity: Int, mediumQuantity: Int, largeQuantity: Int) {

        // Initialize stored properties
        self.smallQuantity = smallQuantity
        self.mediumQuantity = mediumQuantity
        self.largeQuantity = largeQuantity
    }
}

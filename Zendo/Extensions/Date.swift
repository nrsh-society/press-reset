//
//  Date+Event.swift
//  Finance
//
//  Created by Anton Pavlov on 08/04/2018.
//  Copyright © 2018 Anton Pavlov. All rights reserved.
//

import Foundation

import UIKit

let zendoEndFormat = "h:mm a"

extension Date {
    
    var toZendoEndString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = zendoEndFormat
        let res = formatter.string(from: self)
        return res
    }
    
}

//extension String {
//
//    var dateFromZendoEndString: Date? {
//        let formatter = DateFormatter()
//        formatter.dateFormat = zendoEndFormat
//        let res = formatter.date(from: self)
//        return res
//    }
//
//}

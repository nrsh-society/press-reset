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
let zendoDetailMonthFormat = "MMMM d"
let zendoDetailTimeFormat = "h:mma"
let zendoHeaderFormat = "EEEE, MMMM d"
let zendoHeaderDayFormat = "MMMM d"

extension Date {
    
    var toZendoEndString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = zendoEndFormat
        let res = formatter.string(from: self)
        return res
    }
    
    var toZendoDetailsMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = zendoDetailMonthFormat
        let res = formatter.string(from: self)
        return res
    }
    
    var toZendoDetailsTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = zendoDetailTimeFormat
        let res = formatter.string(from: self)
        return res
    }
    
    var toZendoHeaderString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = zendoHeaderFormat
        let res = formatter.string(from: self)
        return res
    }
    
    var toZendoHeaderDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = zendoHeaderDayFormat
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

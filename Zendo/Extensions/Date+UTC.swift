//
//  Date+UTC.swift
//  Zendo
//
//  Created by Anton Pavlov on 15/02/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import UIKit

let kUTCDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS Z"
let kUTCSubscriptionDateFormat = "yyyy-MM-dd HH:mm:ss VV"


extension Date {
    
    var toUTCString: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = kUTCDateFormat
        let res = formatter.string(from: self)
        print(res)
        return res
    }
    
    var toUTCSubscriptionString: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = kUTCSubscriptionDateFormat
        let res = formatter.string(from: self)
        print(res)
        return res
    }
    
    var toVerbalString: String {
        return DateFormatter.localizedString(from: self, dateStyle: .medium, timeStyle: .none)
    }
}

extension String {
    var dateFromUTCString: Date? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = kUTCDateFormat
        let res = formatter.date(from: self)
        return res
    }
    
    var dateFromUTCSubscriptionString: Date? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = kUTCSubscriptionDateFormat
        let res = formatter.date(from: self)
        return res
    }
}

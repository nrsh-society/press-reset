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
let zendoHeaderMonthYearFormat = "MMMM yyyy"
let zendoHeaderYearFormat = "yyyy"


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
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = zendoHeaderDayFormat
        let res = formatter.string(from: self)
        return res
    }
    
    var toZendoHeaderMonthYearString: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = zendoHeaderMonthYearFormat
        let res = formatter.string(from: self)
        return res
    }
    
    var toZendoHeaderYearString: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = zendoHeaderYearFormat
        let res = formatter.string(from: self)
        return res
    }
    
    var startOfWeek: Date {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.autoupdatingCurrent
        let components = gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return gregorian.date(from: components)!
    }
    
    var endOfWeek: Date {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.autoupdatingCurrent
        let components = gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        let endWeek = gregorian.date(byAdding: .day, value: 7, to: gregorian.date(from: components)!)!
        var componentsEnd = gregorian.dateComponents([.second], from: endWeek)
        componentsEnd.minute = -1
        return calender.date(byAdding: componentsEnd, to: endWeek)!
    }
    
    var startOfDay: Date {
        return calender.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calender.date(byAdding: components, to: startOfDay)!
    }
    
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return calender.date(from: components)!
    }
    
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return calender.date(byAdding: components, to: startOfMonth)!
    }
    
    var startOfYear: Date {
        let components = Calendar.current.dateComponents([.year], from: startOfDay)
        return calender.date(from: components)!
    }
    
    var endOfYear: Date {
        var components = DateComponents()
        components.year = 1
        components.day = -1
        return calender.date(byAdding: components, to: startOfYear)!
    }
    
    private var calender: Calendar {
        var calender = Calendar.current
        calender.timeZone = TimeZone.autoupdatingCurrent
        return calender
    }
    
}


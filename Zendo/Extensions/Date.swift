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
let zendoHeaderDayTimeFormat = "MMMM dd 'at' HH:mma"


extension Date {
    
    var startOfDay: Date {
        return calender.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calender.date(byAdding: components, to: startOfDay)!
    }

    static func createFrom(year: Int, month: Int, day: Int) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.timeZone = TimeZone(abbreviation: "UTC")
        dateComponents.hour = 12
        let calendar = Calendar.current
        return calendar.date(from: dateComponents)
    }
    
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
    
    var toZendoHeaderDayTimeString: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = zendoHeaderDayTimeFormat
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
    
    var toZazenDateString : String
    {
        get {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: self)
        }
    }
    
}

extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
}

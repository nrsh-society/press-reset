//
//  TimeInterval.swift
//  Zendo
//
//  Created by Anton Pavlov on 31/07/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation

extension TimeInterval {
    
    private var milliseconds: Int {
        return Int((truncatingRemainder(dividingBy: 1)) * 1000)
    }
    
    private var seconds: Int {
        return Int(self) % 60
    }
    
    private var minutes: Int {
        return (Int(self) / 60 ) % 60
    }
    
    private var hours: Int {
        return Int(self) / 3600
    }
    
    var stringTime: String {
        if hours != 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes != 0 {
            return "\(minutes)m \(seconds)s"
        } else if milliseconds != 0 {
            return "\(seconds)s \(milliseconds)ms"
        } else {
            return "\(seconds)s"
        }
    }
    
    var stringZendoTime: String {
        var hrs = "hrs"
        var mins = "mins"
        
        if hours == 1 {
            hrs = "hr"
        }
        
        if minutes == 1 {
            mins = "min"
        }
        
        if hours != 0 {
            return hours.description + hrs + " " + minutes.description + mins
        } else if minutes != 0 {
            return minutes.description + mins
        } else {
            return seconds.description + "sec"
        }
    }
}

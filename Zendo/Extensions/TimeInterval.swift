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
        return (Int(self) / 60) % 60
    }
    
    private var hours: Int {
        return Int(self) / 3600
    }
    
    var stringZendoTimeMMChart: String {
        let hrs = "h"
        let mins = "m"
    
        if hours != 0 {
            return hours.description + hrs + " " + minutes.description + mins
        } else if minutes != 0 {
            return minutes.description + mins
        } else {
            return seconds.description + "s"
        }
    }
    
    var stringZendoTime: String {
        var hrsStr = "hrs"
        var minsStr = "mins"
        var mins = minutes
        var hrs = hours
        
        if seconds >= 30 {
            mins += 1
            if mins == 60 {
                hrs += 1
                mins = 0
            }
        }
        
        if hrs == 1 {
            hrsStr = "hr "
        }
        
        if mins == 1 || mins == 0{
            minsStr = "min "
        }
        
        if hrs != 0 {
            return hrs.description + hrsStr + " " + mins.description + minsStr
        } else {
            
            if mins < 10
            {
                return "0\(mins)" + minsStr
            }
            else
            {
                return mins.description + minsStr
            }
        }
    }
    
    var stringZendoTimeShort: String {
        let hrsStr = "h"
        let minsStr = "m"
        var mins = minutes
        var hrs = hours
        
        if seconds >= 30 {
            mins += 1
            if mins == 60 {
                hrs += 1
                mins = 0
            }
        }
        
        return (hrs != 0 ? hrs.description + hrsStr : "") + mins.description + minsStr
    }
    
    var stringZendoTimeWatch: String {
        return (hours <= 0 ? "" : hours.description + ":")  +
            (minutes < 10 ? "0" + minutes.description : minutes.description) + ":" +
            (seconds < 10 ? "0" + seconds.description : seconds.description)
    }
}

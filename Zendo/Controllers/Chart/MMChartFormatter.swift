//
//  MMChartFormatter.swift
//  Zendo
//
//  Created by Anton Pavlov on 16/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Charts

@objc(BarChartFormatter)
public class MMChartFormatter: NSObject, IAxisValueFormatter {
    
    var currentInterval: CurrentInterval = .hour
    
    let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let months = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        
        switch currentInterval {
        case .hour, .month: return String(format: "%.0f", value)
        case .day:
            if value >= 1 && value <= 7 {
                return weekdays[Int(value - 1)]
            }
        case .year:
            if value >= 1 && value <= 12 {
                return months[Int(value - 1)]
            }
        }
        
        return String(format: "%.0f", value)
    }
}

public class MMChartValueFormatter: NSObject, IAxisValueFormatter {
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return (value * 60.0).stringZendoTimeMMChart
    }
    
}

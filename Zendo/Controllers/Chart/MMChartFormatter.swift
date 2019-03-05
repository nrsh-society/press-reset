//
//  MMChartFormatter.swift
//  Zendo
//
//  Created by Anton Pavlov on 16/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Charts

public class MMChartFormatter: NSObject, IAxisValueFormatter {
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(format: "%.0f", value)
    }
    
}

public class MMChartFormatterHour: MMChartFormatter {
    
    public override func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(format: "%.0f", value)
    }
    
}

public class MMChartFormatterDay: MMChartFormatter {
    
    let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    public override func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if value > 0.0 && value <= 7.0 {
            return weekdays[Int(value - 1.0)]
        } else {
            return "nil"
        }
    }
    
}

public class MMChartFormatterYear: MMChartFormatter {
    
    let months = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
    
    public override func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if value > 0.0 && value <= 12.0 {
            return months[Int(value - 1.0)]
        } else {
            return "nil"
        }
    }
    
}

public class MMChartValueFormatter: MMChartFormatter {
    
    public override func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return (value * 60.0).stringZendoTimeMMChart
    }
    
}

public class MMChartHRVFormatter: MMChartFormatter {
    
    public override func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return ""
    }
    
}


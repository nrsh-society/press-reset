//
//  Background.swift
//  Zendo WatchKit Extension
//
//  Created by Anton Pavlov on 07/02/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import Foundation
import WatchKit

enum BackgroundType: String {
    case checkCloseRing, closeRing
}


class Background {
    
    static let key = "backgroundType"

    static func scheduleBackgroundRefreshCheckCloseRing() {
        
        var date = Date()
        let calendar = Calendar.autoupdatingCurrent
        let dateComponents = calendar.dateComponents([.hour], from: date)
        
        var fireDate: Date?
        
        if let hour = dateComponents.hour, hour > 20 {
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? Date()
        }
        
        fireDate = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: date)
        
        let userInfo = [key: BackgroundType.checkCloseRing.rawValue] as NSSecureCoding & NSObjectProtocol
        
        if let fireDate = fireDate {
            WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo) { error in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
        
    }
    
    static func scheduleBackgroundRefreshCloseRing() {
        
        let fireDate = Date(timeIntervalSinceNow: 60 * 10)
        
        let userInfo = [key: BackgroundType.closeRing.rawValue] as NSSecureCoding & NSObjectProtocol
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: userInfo ) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
    }


}

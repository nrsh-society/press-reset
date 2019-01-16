//
//  NotificationController.swift
//  Zazen WatchKit Extension
//
//  Created by Douglas Purdy on 12/27/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import WatchKit
import Foundation
import UserNotifications


class NotificationController: WKUserNotificationInterfaceController {

    @IBOutlet var notificationLabel: WKInterfaceLabel!
    @IBOutlet var directionImage: WKInterfaceImage!
    
    override init()
    {
        super.init()
    }

    override func willActivate() {
        
        super.willActivate()
    }

    override func didDeactivate() {
        
        super.didDeactivate()
    }

    
    override func didReceive(_ notification: UNNotification,
                withCompletion completionHandler: @escaping (WKUserNotificationInterfaceType) -> Swift.Void)
    {
        let now = Date()
        let yesterday = now.addingTimeInterval(-60 * 60 * 24)
        
        var lastNow = now
        var lastYesterday = yesterday
        
        var alertText =  "%@ : %@"
        
        switch notification.request.identifier
        {
            case NotificationType.weekSummary.rawValue:
            
                lastNow = now.addingTimeInterval(-60 * 60 * 24 * 7)
                lastYesterday = yesterday.addingTimeInterval(-60 * 60 * 24 * 7)
                alertText =  "Your HRV is %ldms this week from %ldms last week."
            
            case NotificationType.daySummary.rawValue:
            
                lastNow = now.addingTimeInterval(-60 * 60 * 24)
                lastYesterday = yesterday.addingTimeInterval(-60 * 60 * 24)
                alertText =  "Your HRV is %ldms today from %ldms yesterday."
            
            case NotificationType.hourSummary.rawValue:
            
                lastNow = now.addingTimeInterval(-60 * 60)
                lastYesterday = yesterday.addingTimeInterval(-60 * 60)
                alertText =  "Your HRV is %ldms now from %ldms an hour ago."
            
            case NotificationType.minuteSummary.rawValue:
            
                lastNow = now.addingTimeInterval(-60)
                lastYesterday = yesterday.addingTimeInterval(-60 * 60)
                alertText =  "Your HRV is %ldms now from %ldms a minute ago."
            

            default:
                break
        }

        
        ZBFHealthKit.getHRVAverage(start: yesterday, end: now)
        {
            (samples, error) in
            
            let todayHRV = Int(samples![0]!)
            
            ZBFHealthKit.getHRVAverage(start: lastYesterday, end: lastNow)
            {
                (samples, error) in
                
                let last_hrv = Int(samples![0]!)
                
                let hrv_delta = Int(todayHRV - last_hrv)
                
                alertText = String(format: alertText, hrv_delta, last_hrv)
                
                var arrowImage = "equal"
                
                if hrv_delta < 0
                {
                    arrowImage = "down"
                }
                else if hrv_delta > 0
                {
                    arrowImage = "up"
                }
                
                DispatchQueue.main.async
                {
                    self.notificationLabel.setText(alertText)
                }
                
                completionHandler(.custom)
            }
        }
        
    }
    
}

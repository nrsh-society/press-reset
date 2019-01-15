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
    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
    override func didReceive(_ notification: UNNotification, withCompletion completionHandler: @escaping (WKUserNotificationInterfaceType) -> Swift.Void) {
    
        
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        
        var lastNow = now.addingTimeInterval(-604800)
        var lastYesterday = yesterday.addingTimeInterval(-604800)
        
        var hrv_delta = 0
        var last_hrv = 0
        
        var alertText =  "Your HRV is \(hrv_delta)ms this week from \(last_hrv)ms last week."

        
        switch notification.request.identifier
        {
            case NotificationType.weekSummary.rawValue:
            
                lastNow = now.addingTimeInterval(-604800)
                lastYesterday = yesterday.addingTimeInterval(-604800)
            
                alertText =  "Your HRV is \(hrv_delta)ms this week from \(last_hrv)ms last week."

            
            case NotificationType.daySummary.rawValue:
            
                lastNow = now.addingTimeInterval(-60 * 60 * 24)
                lastYesterday = yesterday.addingTimeInterval(-60 * 60 * 24)
            
                alertText =  "Your HRV is \(hrv_delta)ms today from \(last_hrv)ms yesterday."

            
            case NotificationType.hourSummary.rawValue:
            
                lastNow = now.addingTimeInterval(-60 * 60)
                lastYesterday = yesterday.addingTimeInterval(-60 * 60)
            
                alertText =  "Your HRV is \(hrv_delta)ms now from \(last_hrv)ms an hour ago."

            
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
                
                last_hrv = Int(samples![0]!)
                
                hrv_delta = todayHRV - last_hrv
                
                self.notificationLabel.setText(alertText)
            }
        }
        
        completionHandler(.custom)
    
    }
    
}

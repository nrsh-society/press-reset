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
    @IBOutlet var notificationTitle: WKInterfaceLabel!
    
    override init()
    {
        super.init()
    }

    override func willActivate()
    {
        
        super.willActivate()
    }

    override func didDeactivate()
    {
        super.didDeactivate()
    }

    
    override func didReceive(_ notification: UNNotification)
    {
        
        let mediateAction = UNNotificationAction(identifier: "MEDIATE_ACTION",
                                                 title: "Mediate Now",
                                                 options: UNNotificationActionOptions.foreground)
        
        if #available(watchOSApplicationExtension 5.0, *) {
            self.notificationActions.append(mediateAction)
        } else {
            // Fallback on earlier versions
        }
    
    }
    
    override func didReceive(_ notification: UNNotification,
                withCompletion completionHandler: @escaping (WKUserNotificationInterfaceType) -> Swift.Void)
    {
        
        
        

        let now = Date()
        let yesterday = now.addingTimeInterval(-60 * 60 * 24)
        
        var lastNow = now
        var lastYesterday = yesterday
        
        var alertText =  "%@ : %ld"
        var alertTitle = "HRV Summary"
        
        switch notification.request.identifier
        {
            case NotificationType.weekSummary.rawValue:
            
                lastNow = now.addingTimeInterval(-60 * 60 * 24 * 7)
                lastYesterday = yesterday.addingTimeInterval(-60 * 60 * 24 * 7)
                alertText =  "Your HRV changed %@ms from %ldms last week."
                alertTitle = "Weekly Summary"
            
            case NotificationType.daySummary.rawValue:
            
                lastNow = now.addingTimeInterval(-60 * 60 * 24)
                lastYesterday = yesterday.addingTimeInterval(-60 * 60 * 24)
                alertText =  "Your HRV changed %@ms from %ldms yesterday."
                alertTitle = "Daily Summary"
            
            case NotificationType.hourSummary.rawValue:
            
                lastNow = now.addingTimeInterval(-60 * 60)
                lastYesterday = yesterday.addingTimeInterval(-60 * 60)
                alertText =  "Your HRV changed %@ms from %ldms an hour ago."
                alertTitle = "Hourly Summary"
            
            case NotificationType.minuteSummary.rawValue:
            
                lastNow = now.addingTimeInterval(-60)
                lastYesterday = yesterday.addingTimeInterval(-60 * 60 * 5)
                alertText =  "Your HRV changed %@ms from %ldms 5 minutes ago."
                alertTitle = "5min Summary"

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
                
                var arrow = ""
                
                if hrv_delta < 0
                {
                    arrow = "▾"
                }
                else if hrv_delta > 0
                {
                    arrow = "▴"
                }
                
                let hrv_delta_string = arrow + String(hrv_delta)
                
                alertText = String(format: alertText, hrv_delta_string, last_hrv)
                
                DispatchQueue.main.async
                {
                    
                    self.notificationTitle.setText(alertTitle)
                    
                    let textString = NSMutableAttributedString(string: alertText)
                    
                    let textRange = NSRange(location: 0, length: textString.length)
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineSpacing = 1.32
                    textString.addAttribute(NSAttributedStringKey.paragraphStyle, value:paragraphStyle, range: textRange)
                    
                    self.notificationLabel.setAttributedText(textString)

                }
                
                completionHandler(.custom)
            }
        }
        
    }
    
}

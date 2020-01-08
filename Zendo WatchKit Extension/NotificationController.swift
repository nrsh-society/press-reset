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
import Mixpanel


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
        
        Mixpanel.sharedInstance()?.track("watch_localnotification")
        
        let meditateAction = UNNotificationAction(identifier: "MEDITATE_ACTION",
                                                 title: "Meditate Now",
                                                 options: UNNotificationActionOptions.foreground)
        
        if #available(watchOSApplicationExtension 5.0, *) {
            self.notificationActions.append(meditateAction)
        } else {
            // Fallback on earlier versions
        }
        
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
            
            lastNow = now.addingTimeInterval(-60 * 60 * 5)
            lastYesterday = yesterday.addingTimeInterval(-60 * 60 * 5)
            alertText =  "Your HRV changed %@ms from %ldms 5 minutes ago."
            alertTitle = "5min Summary"
            
        case NotificationType.checkCloseRing.rawValue:
            
            alertText =  "Consistent mindfulness leads to positive health outcomes. Don’t forget to close your mindulfulness ring."
            alertTitle = "You Got This!"
            
        case NotificationType.closeRing.rawValue:
            
            alertText =  "You reached your daily mindfulness goal!"
            alertTitle = "Congrats!"
            
            if #available(watchOSApplicationExtension 5.0, *) {
                notificationActions.removeAll()
            }
            
        default:
            break
        }
        
        
        self.notificationTitle.setText(alertTitle)
        self.notificationLabel.setText(alertText)
        
        ZBFHealthKit.getHRVAverage(start: yesterday, end: now)
        {
            (samples, error) in
            
            var todayHRV = 0

            if let samp = samples, let first = samp[0] {
                todayHRV = Int(first)
            }

            ZBFHealthKit.getHRVAverage(start: lastYesterday, end: lastNow)
            {
                (samples, error) in

                var last_hrv = 0

                if let samp = samples, let first = samp[0] {
                    last_hrv = Int(first)
                }

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

                let hrv_delta_string = arrow + abs(hrv_delta).description
                
                
                switch notification.request.identifier {
                case NotificationType.weekSummary.rawValue:
                    if hrv_delta == 0 {
                        alertText = String(format: "Your HRV this week is the same as last week’s %ldms.", last_hrv)
                    } else {
                        alertText = String(format: alertText, hrv_delta_string, last_hrv)
                    }
                    
                case NotificationType.checkCloseRing.rawValue,
                     NotificationType.closeRing.rawValue:
                    break
                default:
                    alertText = String(format: alertText, hrv_delta_string, last_hrv)
                }
                
                self.notificationTitle.setText(alertTitle)
                self.notificationLabel.setText(alertText)
                
                let textString = NSMutableAttributedString(string: alertText)
                
                let textRange = NSRange(location: 0, length: textString.length)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 1.50
                textString.addAttribute(NSAttributedStringKey.paragraphStyle, value:paragraphStyle, range: textRange)
                
                self.notificationLabel.setAttributedText(textString)
            }
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
            
                lastNow = now.addingTimeInterval(-60 * 60 * 5)
                lastYesterday = yesterday.addingTimeInterval(-60 * 60 * 5)
                alertText =  "Your HRV changed %@ms from %ldms 5 minutes ago."
                alertTitle = "5min Summary"

            default:
                break
        }

        
        self.notificationTitle.setText(alertTitle)
        self.notificationLabel.setText(alertText)
        
        ZBFHealthKit.getHRVAverage(start: yesterday, end: now)
        {
            (samples, error) in
            
            var todayHRV = 0

            if let samp = samples, let first = samp[0] {
                todayHRV = Int(first)
            }
            
            ZBFHealthKit.getHRVAverage(start: lastYesterday, end: lastNow)
            {
                (samples, error) in

                var last_hrv = 0

                if let samp = samples, let first = samp[0] {
                    last_hrv = Int(first)
                }
                
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
                
                let hrv_delta_string = arrow + abs(hrv_delta).description
                
                alertText = String(format: alertText, hrv_delta_string, last_hrv)
                
                //DispatchQueue.main.async
                //{
                    
                    self.notificationTitle.setText(alertTitle)
                    self.notificationLabel.setText(alertText)
                    
                
                    let textString = NSMutableAttributedString(string: alertText)
                    
                    let textRange = NSRange(location: 0, length: textString.length)
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineSpacing = 1.50
                    textString.addAttribute(NSAttributedStringKey.paragraphStyle, value:paragraphStyle, range: textRange)
                    
                    self.notificationLabel.setAttributedText(textString)
                
               // }
                
                completionHandler(.custom)
            }
        }
        
    }
    
}

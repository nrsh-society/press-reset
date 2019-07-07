//
//  Notification.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 1/14/19.
//  Copyright © 2019 zenbf. All rights reserved.
//

import Foundation
import UserNotifications
import WatchConnectivity

/*
 At end of watch summary...
 
 1: do we have notification permission?
 2: if no, ask for it.
 3: if given, schedule weekly notification.
 
 question: Add option switch for none, daily, weekly notifications?
 
 
 if !Settings.requestedNotificationPermission
 {
 
 */

public enum NotificationType : String
{
    case minuteSummary
    case hourSummary
    case daySummary
    case weekSummary
    case checkCloseRing
    case closeRing
}

public class Notification
{
    
    static let defaults = UserDefaults.standard
    
    private static var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    typealias StatusHandler = ((UNAuthorizationStatus) -> Void)
    typealias AuthHandler = ((Bool, Error?) -> Void)
    
    static var enabled: Bool {
        set {
            defaults.set(newValue, forKey: "notificationEnabled")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "notificationEnabled")
        }
    }
    
    static var isShowNotificationCloseRing: Bool {
        set {
            defaults.set(newValue, forKey: "isShowNotificationCloseRing")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "isShowNotificationCloseRing")
        }
    }
    
    static func status(handler: @escaping Notification.StatusHandler)
    {
        UNUserNotificationCenter.current().getNotificationSettings
            {
                settings in
                
                print("Notification settings: \(settings)")
                
                handler(settings.authorizationStatus)
        }
    }
    
    static func auth(handler: @escaping AuthHandler)
    {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        {
            granted, error in
            
            //#todo: logging
            print("Permission granted: \(granted)")
            
            sessionDelegater.sendMessage(
                ["watch" : "registerNotifications"],
                replyHandler:
                {
                    (replyMessage) in
                    
                    print(replyMessage.debugDescription)
                    
            },
                errorHandler:
                {
                    (error) in
                    
                    print(error.localizedDescription)
            })
            
            handler(granted, error)
        }
    }
    
    static func weekly()
    {
        let content = UNMutableNotificationContent()
        
        content.title = "Weekly Summary"
        content.body = "Has your mental fitness improved?"
        content.sound = UNNotificationSound.default()
        
        content.categoryIdentifier = "HrvSummary"
        
        var date = DateComponents()
        date.weekday = 6
        date.hour = 12
        date.minute = 0
        date.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        
        let request = UNNotificationRequest(identifier: NotificationType.weekSummary.rawValue, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        {
            error in
            
            if let error = error
            {
                print("\(error)")
            }
        }
    }
    
    static func daily()
    {
        let content = UNMutableNotificationContent()
        
        content.title = "Daily Summary"
        content.body = "Has your mental fitness improved?"
        content.categoryIdentifier = "HrvSummary"
        content.sound = UNNotificationSound.default()
        
        
        var date = DateComponents()
        date.hour = 21
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        
        let request = UNNotificationRequest(identifier: NotificationType.daySummary.rawValue,
                                            content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        {
            error in
            
            if let error = error
            {
                print("\(error)")
            }
        }
    }
    
    static func hourly()
    {
        
        let content = UNMutableNotificationContent()
        
        content.title = "Hourly Summary"
        content.body = "Has your mental fitness improved?"
        content.categoryIdentifier = "HrvSummary"
        content.sound = UNNotificationSound.default()
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60, repeats: true)
        
        let request = UNNotificationRequest(identifier: NotificationType.hourSummary.rawValue, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        {
            error in
            
            if let error = error
            {
                print("\(error)")
            }
        }
    }
    
    static func minute()
    {
        
        let content = UNMutableNotificationContent()
        
        content.title = "Debug Summary"
        content.categoryIdentifier = "HrvSummary"
        content.body = "Has your mental fitness improved?"
        content.sound = UNNotificationSound.default()
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 5, repeats: true)
        
        let request = UNNotificationRequest(identifier: NotificationType.minuteSummary.rawValue, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        {
            error in
            
            if let error = error
            {
                print("\(error)")
            }
        }
    }
    
    
    /*
     #todo: only one of these notifications is running as of v5.00
     */
    static func checkCloseRing() {
        
        ZBFHealthKit.getMindfulMinutes { sec, error in
            
            let goalMins = SettingsWatch.dailyMediationGoal
            
            if let sec = sec {
                let mins = sec / 60.0
                
                let percent = Int(((mins / Double(goalMins)) * 100.0))
                
                if percent < 100 {
                    
                    let content = UNMutableNotificationContent()
                    
                    content.title = "You Got This!"
                    content.categoryIdentifier = "HrvSummary"
                    content.body = "Mindfulness improves mental fitness. Remember to close your ring today."
                    content.sound = UNNotificationSound.default()
                    
                    let request = UNNotificationRequest(identifier: NotificationType.checkCloseRing.rawValue, content: content, trigger: nil)
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                    
                }
                
            }
        }
        
    }
    
    static func closeRing() {
        
        ZBFHealthKit.getMindfulMinutes { sec, error in
            
            let goalMins = SettingsWatch.dailyMediationGoal
            
            if let sec = sec {
                let mins = sec / 60.0
                
                let percent = Int(((mins / Double(goalMins)) * 100.0))
                
                if percent < 100 && isShowNotificationCloseRing {
                    isShowNotificationCloseRing = false
                }
                
                if percent >= 100 && !isShowNotificationCloseRing {
                    
                    isShowNotificationCloseRing = true
                    
                    let content = UNMutableNotificationContent()
                    
                    content.title = "Congrats!"
                    content.categoryIdentifier = "HrvSummary"
                    content.body = "You closed your mindfulness ring."
                    content.sound = UNNotificationSound.default()
                    
                    let request = UNNotificationRequest(identifier: NotificationType.closeRing.rawValue, content: content, trigger: nil)
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                    
                }
                
            }
        }
        
    }
}

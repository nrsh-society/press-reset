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
}

public class Notification
{
    
    private static var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    typealias StatusHandler = ((UNAuthorizationStatus) -> Void)
    typealias AuthHandler = ((Bool, Error?) -> Void)
    
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
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
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
        date.day = 6
        date.hour = 21
        
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
}

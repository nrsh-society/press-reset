//
//  Notification.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 1/14/19.
//  Copyright © 2019 zenbf. All rights reserved.
//

import Foundation
import UserNotifications

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
    
    case hourSummary
    case daySummary
    case weekSummary
}

public class Notification
{
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
            
            print("Permission granted: \(granted)")
            
            handler(granted, error)
            
            /*
            * this has to happen on the phone
             DispatchQueue.main.async
                {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            */
        }
    }
    
    static func weekly()
    {
        //var seconds_per_week = 60 * 60 * 24 * 7
        
        let content = UNMutableNotificationContent()
        
        content.title = "Weekly HRV Summary"
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
        
        content.title = "Daily HRV Summary"
        content.categoryIdentifier = "HrvSummary"
        
        var date = DateComponents()
        date.hour = 21
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        
        let request = UNNotificationRequest(identifier: NotificationType.daySummary.rawValue, content: content, trigger: trigger)
        
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
        
        content.title = "Hourly HRV Summary"
        content.categoryIdentifier = "HrvSummary"
        
        var date = DateComponents()
        date.hour = 1
   
        //let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        
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
}

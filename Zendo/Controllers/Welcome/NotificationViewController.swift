//
//  NotificationViewController.swift
//  Zendo
//
//  Created by Douglas Purdy on 1/4/19.
//  Copyright © 2019 zenbf. All rights reserved.
//

import UIKit
import Foundation
import HealthKit
import Mixpanel
import UserNotifications

class NotificationViewController: UIViewController
{
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        Mixpanel.mainInstance().time(event: "phone_notification")
        
        UNUserNotificationCenter.current().getNotificationSettings
        {
            settings in
            
            print("Notification settings: \(settings)")
            
            //#todo: if notifications have already been granted
            // dimiss?
            //if notifications have been denied, show some kind of UI to ask them to turn them on?
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "phone_notification")
        
        Settings.requestedNotificationPermission = true
    }
    
    class func loadFromStoryboard() -> NotificationViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NotificationViewController") as! NotificationViewController
    }
    
    @IBAction func grantButtonAction(_ sender: Any)
    {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
        {
                granted, error in
            
                print("Permission granted: \(granted)")
                
                DispatchQueue.main.async
                {
                    UIApplication.shared.registerForRemoteNotifications()
                }
        }
        
        self.dismiss(animated: true) {
            
        }
    }
}

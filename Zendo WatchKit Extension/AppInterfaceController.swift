//
//  InterfaceController.swift
//  Zazen WatchKit Extension
//
//  Created by Douglas Purdy on 12/27/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import Mixpanel
import UserNotifications

class AppInterfaceController: WKInterfaceController {
    
    @IBOutlet var hrvLabel: WKInterfaceLabel!
    @IBOutlet var mainGroup: WKInterfaceGroup!
    
    func openUrl(urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        
        NSExtensionContext().open(url)
    }
    
    @IBAction func start() {
        
        ZBFHealthKit.getPermissions()
        {
            [weak self] success, error in
            
            Mixpanel.sharedInstance()?.track("watch_healthkit", properties: ["success" : success])
            
            guard error == nil else
            {
                let ok = WKAlertAction(title: "OK", style: .default)
                {
                    self?.openUrl(urlString: "x-apple-health://")
                    
                }
                
                self?.presentAlert(withTitle: nil, message: "Zendō needs access to Apple Health. Nothing is shared with us or anyone else without your permission.", preferredStyle: .alert, actions: [ok])
                
                return
            }
            
            if success
            {
                DispatchQueue.main.async()
                {
                    self?.startSession()
                }
            }
        }
        
    }
    
    func startSession() {
        
        Mixpanel.sharedInstance()?.track("watch_new_session")
        
        Session.current = Session()
        
        Session.current?.start()
        
        WKInterfaceDevice.current().play(WKHapticType.start)
        
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SessionInterfaceController", context: Session.current as AnyObject)])
    }
    
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        
        if let session = context as? Session
        {
            if(!session.isRunning)
            {
                Notification.status()
                {
                    status in
                        
                    if(status == .notDetermined)
                    {
                        Notification.auth()
                        {
                            (granted, error) in
                                    
                            if(granted)
                            {
                                self.enableLocalNotifications()
                            }
                            
                            Mixpanel.sharedInstance()?.track("watch_notification_auth")
                        }
                    }
                    
                    if(status == .authorized)
                    {
                        self.enableLocalNotifications()
                    }
                }
            }
        }
        
        UserDefaults.standard.register(defaults: [SettingsWatch.dailyMediationGoalKey: 5])

        //#todo(v5.1): make the mindfulness checking work again.
        //Background.scheduleBackgroundRefreshCheckCloseRing()
        //Background.scheduleBackgroundRefreshCloseRing()
    }
    
    func enableLocalNotifications()
    {
        //fix bug in 4.2 notifications
        if(SettingsWatch.localNotications)
        {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        
        if(!Notification.enabled)
        {
            #if DEBUG
                //Notification.minute()
                //Notification.hourly()
                //Notification.daily()
            #endif
            
            Notification.weekly()
            
            Notification.daily()
            
            Notification.enabled = true
            
            Mixpanel.sharedInstance()?.track("watch_notification_enabled")
        }
    }
    
    
    override func willActivate()
    {
        super.willActivate()
        
        ZBFHealthKit.getPermissions()
        {
            [weak self] success, error in
            
            Mixpanel.sharedInstance()?.track("watch_healthkit", properties: ["success" : success])
            
            guard error == nil else
            {
                let ok = WKAlertAction(title: "OK", style: .default)
                {
                    self?.openUrl(urlString: "x-apple-health://")
                }
                DispatchQueue.main.async()
                {
                self?.presentAlert(withTitle: nil, message: "Zendō needs access to Apple Health. Nothing is shared with us or anyone else without your permission.", preferredStyle: .alert, actions: [ok])
                }
                return
            }
            
            if(success)
            {
                ZBFHealthKit.getHRVAverage()
                {
                    value, error in
                    
                    DispatchQueue.main.async()
                    {
                        if value > 0.0
                        {
                            self?.hrvLabel.setText(Int(value.rounded()).description + "ms")
                        }
                    }
                }
                
                ZBFHealthKit.getMindfulMinutes()
                {
                    sec, error in

                    DispatchQueue.main.async()
                    {
                    
                        let currentPercent = SettingsWatch.currentDailyMediationPercent
                        let goalMins = SettingsWatch.dailyMediationGoal
                    
                        if let sec = sec
                        {
                            let mins = sec / 60.0
                        
                            let percent = Int(((mins / Double(goalMins)) * 100.0) / 2.0)

                            if percent >= 161
                            {
                                self?.mainGroup.setBackgroundImageNamed("ring161")
                                return
                            }

                            self?.mainGroup.setBackgroundImageNamed("ring")

                            if currentPercent < percent {
                                self?.mainGroup.startAnimatingWithImages(in:
                                NSRange(location: currentPercent, length: percent - currentPercent),
                                                                    duration: 0.6, repeatCount: 1)
                            } else if currentPercent > percent {
                                self?.mainGroup.setBackgroundImageNamed("ring\(percent)")

                            } else {
                                self?.mainGroup.setBackgroundImageNamed("ring\(percent)")
                            }

                        SettingsWatch.currentDailyMediationPercent = percent

                    }
                    else
                    {
                        self?.mainGroup.setBackgroundImageNamed("ring0")
                    }
                    }
                }
            }
            
        }
        
        Mixpanel.sharedInstance()?.timeEvent("watch_overview")
    }
    
    override func didDeactivate()
    {
        super.didDeactivate()
        
        Mixpanel.sharedInstance()?.track("watch_overview")
    }
    
}

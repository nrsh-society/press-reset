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

//var _currentSession : Session?

class AppInterfaceController: WKInterfaceController {
    
    @IBOutlet var hrvLabel: WKInterfaceLabel!
    @IBOutlet var mainGroup: WKInterfaceGroup!
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    
    @IBAction func start() {
        
        NSLog("start press")
        
        startSession()
        
    }
    
    func startSession() {
        
        Mixpanel.sharedInstance()?.track("watch_new_session")
        
        Session.current = Session()
        
        Session.current?.start()
        
        WKInterfaceDevice.current().play(WKHapticType.start)
        
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SessionInterfaceController", context:  Session.current  as AnyObject)])
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

        Background.scheduleBackgroundRefreshCheckCloseRing()
        Background.scheduleBackgroundRefreshCloseRing()
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
                // Notification.minute()
               // Notification.hourly()
                // Notification.daily()
            #endif
            
            
            Notification.weekly()
            
            Notification.enabled = true
            
            Mixpanel.sharedInstance()?.track("watch_notification_enabled")
        }
    }
    
    override func willActivate()
    {

        super.willActivate()
        
        Mixpanel.sharedInstance()?.timeEvent("watch_overview")
        
        sessionDelegater.sendMessage(["facebook" : "watch_overview"],
            replyHandler:
            {
                (message) in
                
                print(message.debugDescription)
            },
            errorHandler:
            {
                (error) in
                
                print(error)
            })
        
        ZBFHealthKit.getPermissions()
        
        let hkType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let yesterday = Calendar.autoupdatingCurrent.startOfDay(for: Date())
    
        let hkPredicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date(), options: .strictStartDate)
        
        let options = HKStatisticsOptions.discreteAverage
        
        let hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: options)
            {
                query, result, error in
                                            
                    if error != nil
                    {
                        print(error.debugDescription)
                    }
                    else
                    {
                        if let value = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "ms"))
                        {
                            DispatchQueue.main.async()
                            {
                                if value > 0.0
                                {
                                    self.hrvLabel.setText(Int(value.rounded()).description + "ms")
                                }
                            }
                        }
                    }
            }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
        ZBFHealthKit.getMindfulMinutes { sec, error in

            let currentPercent = SettingsWatch.currentDailyMediationPercent
            let goalMins = SettingsWatch.dailyMediationGoal
            
            if let sec = sec {
                let mins = sec / 60.0
                
                let percent = Int(((mins / Double(goalMins)) * 100.0) / 2.0)

                if percent >= 161 {
                    self.mainGroup.setBackgroundImageNamed("ring161")
                    return
                }

                self.mainGroup.setBackgroundImageNamed("ring")

                if currentPercent < percent {
                    self.mainGroup.startAnimatingWithImages(in:
                        NSRange(location: currentPercent, length: percent - currentPercent),
                                                            duration: 0.6, repeatCount: 1)
                } else if currentPercent > percent {
                    self.mainGroup.setBackgroundImageNamed("ring\(percent)")
//                    self.mainGroup.startAnimatingWithImages(in:
//                        NSRange(location: currentPercent, length: percent - currentPercent),
//                                duration: 0.6, repeatCount: 1)
                } else {
                    self.mainGroup.setBackgroundImageNamed("ring\(percent)")
                }

                SettingsWatch.currentDailyMediationPercent = percent

            } else {
                self.mainGroup.setBackgroundImageNamed("ring0")
            }
        }
    }
    
    override func didDeactivate()
    {
        super.didDeactivate()
        
        Mixpanel.sharedInstance()?.track("watch_overview")
    }
    
}

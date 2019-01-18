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

//var _currentSession : Session?

class AppInterfaceController: WKInterfaceController {
    
    @IBOutlet var hrvLabel: WKInterfaceLabel!
    @IBOutlet var mainGroup: WKInterfaceGroup!
    
    
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
                        }
                    }
                    
                    if(status == .authorized)
                    {
                        self.enableLocalNotifications()
                    }
                }
            }
        }
        
    }
    
    func enableLocalNotifications()
    {
        if(!SettingsWatch.localNotications)
        {
            #if DEBUG
                Notification.minute()
                Notification.hourly()
                Notification.daily()
            #endif
            
            Notification.weekly()
            
            SettingsWatch.localNotications = true
            
            Mixpanel.sharedInstance()?.track("enableLocalNotifications")
        }
        
    }
    
    override func willActivate()
    {

        super.willActivate()
        
        Mixpanel.sharedInstance()?.timeEvent("watch_overview")
        
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
    }
    
    override func didDeactivate()
    {
        super.didDeactivate()
        
        Mixpanel.sharedInstance()?.track("watch_overview")
    }
    
}

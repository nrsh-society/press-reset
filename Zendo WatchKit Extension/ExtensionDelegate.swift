//
//  ExtensionDelegate.swift
//  Zazen WatchKit Extension
//
//  Created by Douglas Purdy on 12/27/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import Parse
import WatchKit
import Mixpanel
import HealthKit
import WatchConnectivity
import UserNotifications

class ExtensionDelegate: NSObject, WKExtensionDelegate, SessionCommands, UNUserNotificationCenterDelegate {
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    let healthStore = HKHealthStore()
    
    override init()
    {
        super.init()
        WCSession.default.delegate = sessionDelegater
        WCSession.default.activate()
    }
    
    func applicationDidFinishLaunching()
    {
        if(!Parse.isLocalDatastoreEnabled)
        {
            Parse.enableLocalDatastore()
        }
        
        let parseConfig = ParseClientConfiguration
        {
            $0.applicationId = "APPLICATION_ID"
            $0.server = "http://code.zendo.tools:1337/parse"
            $0.clientKey = "CLIENT_KEY"
        }
        
        Parse.initialize(with: parseConfig)
        
        if let appleId = SettingsWatch.appleUserID
        {
            if SettingsWatch.registered
            {
                PFUser.logInWithUsername(inBackground: appleId, password: String(appleId.prefix(9)))
                
                SettingsWatch.loggedIn = true
            }
            else
            {
                let user = PFUser()
                user.username = appleId
                user.password = String(appleId.prefix(9))
                user.email = SettingsWatch.email
                
                user.signUpInBackground
                {
                    (succeeded, error) in
                    
                    if let error = error
                    {
                        print(error.localizedDescription)
                        
                        SettingsWatch.registered = false
                        
                    }
                    else
                    {
                        SettingsWatch.registered = true
                    }
                }
            }
        }
        

        if let user = PFUser.current()
        {
            user.donations = SettingsWatch.donations
            user.donatedMinutes = SettingsWatch.donatedMinutes
            user.progress = SettingsWatch.progress
            user.progressPosition = SettingsWatch.progressPosition ?? "-/-"
            user.progress = SettingsWatch.progress
            user.successFeedbackLevel = Options().hapticStrength
            user.retryFeedbackLevel = Options().retryStrength
                            
            //todo
            user["_email"] = SettingsWatch.email
            user["_fullname"] = SettingsWatch.fullName
            user["localNotications"] = SettingsWatch.localNotications
            user["dailyMediationGoal"] = SettingsWatch.dailyMediationGoal
            user["currentDailyMediationPercent"] = SettingsWatch.currentDailyMediationPercent
            
            user.saveInBackground()
            
            user.track("watch_login")
            
            SettingsWatch.loggedIn = true
        }
        
        requestAccessToHealthKit()
        
        Mixpanel.sharedInstance(withToken: "73167d0429d8da0c05c6707e832cbb46")

        if let name = SettingsWatch.fullName, let email = SettingsWatch.email
        {
            Mixpanel.sharedInstance()?.identify(email)
            Mixpanel.sharedInstance()?.people.set(["$email": email])
            Mixpanel.sharedInstance()?.people.set(["$name": name])

        }
        else
        {
            sendMessage(["watch": "mixpanel"], replyHandler: { reply in
                if let reply = reply as? [String: String],
                    let email = reply["email"],
                    let name = reply["name"] {
                    
                    if let user = PFUser.current()
                    {
                        user.email = email
                        user["fullname"] = name
                        user.saveInBackground()
                    }

                    SettingsWatch.fullName = name
                    SettingsWatch.email = email

                    Mixpanel.sharedInstance()?.createAlias(email, forDistinctID: (Mixpanel.sharedInstance()?.distinctId)!)

                    Mixpanel.sharedInstance()?.identify(email)
                    Mixpanel.sharedInstance()?.people.set(["$email": email])
                    Mixpanel.sharedInstance()?.people.set(["$name": name])
                }
            }, errorHandler: { (error) in
                print(error.localizedDescription)
            })
        }
        
        if(SettingsWatch.progress)
                {
                    
                        PFCloud.callFunction(inBackground: "rank",
                                             withParameters: ["id": SettingsWatch.appleUserID as Any, "donatedMinutes": SettingsWatch.donatedMinutes ])
                        {
                            (response, error) in

                            if let error = error
                            {
                                print(error)
                            }
                            else
                            {
                                if let rank = response as? String
                                {
                                    SettingsWatch.progressPosition = rank
                                }
                            }
                        }
                }
    
    }
    
    func applicationDidBecomeActive() {
//        requestAccessToHealthKit()
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
    
    func requestAccessToHealthKit() {
        if #available(watchOSApplicationExtension 5.0, *) {
            SettingsWatch.checkAuthorizationStatus { [weak self] success in
                if !success {
                    let healthKitTypes = SettingsWatch.getHealthKitTypes()
                    
                    self?.healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { success, error in
                        print("Successful HealthKit Authorization from Watch's extension Delegate")
                    }
                }
            }
        }
    }
        
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                
                if let userInfo = backgroundTask.userInfo as? [String: String] {
                    
                    switch userInfo[Background.key] {
                    case BackgroundType.checkCloseRing.rawValue:
                        
                        Notification.checkCloseRing()
                        Background.scheduleBackgroundRefreshCheckCloseRing()
                        
                    case BackgroundType.closeRing.rawValue:
                        
                        Notification.closeRing()
                        Background.scheduleBackgroundRefreshCloseRing()
                        
                    default: break
                    }
                    
                }
                
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
        
    }
    
    public func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        if Session.current != nil && (Session.current?.isRunning)! {
            return
        }
        
        requestAccessToHealthKit()
        
        Session.current = Session()
        
        Session.current?.start()
        
        WKInterfaceDevice.current().play(WKHapticType.start)
        
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SessionInterfaceController", context: Session.current as AnyObject), (name: "OptionsInterfaceController", context: Session.current as AnyObject)])
    }
    
}

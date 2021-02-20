 //
//  AppDelegate.swift
//  Zazen
//
//  Created by Douglas Purdy on 12/27/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import UIKit
import HealthKit
import Mixpanel
import FBSDKCoreKit
import UserNotifications
import FBSDKLoginKit
import FacebookCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var foregrounder: Foregrounder!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool {
        
        Settings.isZensorConnected = false
        
        Cloud.enable(application, launchOptions)
        
        WatchSessionManager.sharedManager.startSession()
        
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().barTintColor = UIColor.zenDarkGreen
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().titleTextAttributes = [.font: UIFont.zendo(font: .antennaMedium, size: 24.0), .foregroundColor: UIColor.white]
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont.zendo(font: .antennaMedium, size: 24.0), .foregroundColor: UIColor.white]
        
        UIBarButtonItem.appearance().setTitleTextAttributes([.font: UIFont.zendo(font: .antennaRegular, size: 14.0), .foregroundColor: UIColor.white], for: .normal)
        
        
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.zenDarkGreen], for: .selected)
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.zenLightGreen], for: .normal)
        
        UITabBar.appearance().tintColor = UIColor.zenDarkGreen
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
    
        let workoutSessionReporter = WorkoutSessionReporter()
        workoutSessionReporter.loadOptInCandidates()

        if let window = window
        {
            foregrounder = Foregrounder(window: window,
                                        workoutSessionReporter: workoutSessionReporter)
        }
                        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
    {
        return ApplicationDelegate.shared.application(app, open: url, options: options)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
        foregrounder.execute()
    }
    
    func applicationShouldRequestHealthAuthorization(_ application: UIApplication)
    {
        ZBFHealthKit.getPermissions()
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.portrait
    }
    
    func application(_ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        if let email = Settings.email
        {
            Mixpanel.mainInstance().identify(distinctId: email)
            
            Mixpanel.mainInstance().people.set(properties: ["$email": email])
            
            if let name = Settings.fullName
            {
                Mixpanel.mainInstance().people.set(properties: ["$name": name])
            }
            
            Mixpanel.mainInstance().people.addPushDeviceToken(deviceToken)
        }
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)
    {
        print("Failed to register: \(error)")
    }
}


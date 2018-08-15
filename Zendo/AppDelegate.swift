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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Mixpanel.initialize(token: "73167d0429d8da0c05c6707e832cbb46")
        BuddyBuildSDK.setup()
        CommunityDataLoader.load()
        
        UINavigationBar.appearance().barTintColor = UIColor.zenDarkGreen
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().titleTextAttributes = [.font: UIFont.zendo(font: .antennaMedium, size: 24.0), .foregroundColor: UIColor.white]
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont.zendo(font: .antennaMedium, size: 24.0), .foregroundColor: UIColor.white]
        
        UIBarButtonItem.appearance().setTitleTextAttributes([.font: UIFont.zendo(font: .antennaRegular, size: 14.0), .foregroundColor: UIColor.white], for: .normal)
        
        
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.zenDarkGreen], for: .selected)
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.zenLightGreen], for: .normal)
        
        UITabBar.appearance().tintColor = UIColor.zenDarkGreen
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        //#todo
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
         //#todo
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
         //#todo
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if let vc = window?.topViewController {
            if let tabVc = vc as? UITabBarController, let selectedVc = tabVc.selectedViewController {
                selectedVc.checkHealthKit(isShow: true)
            } else {
                vc.checkHealthKit(isShow: !vc.isKind(of: HealthKitViewController.self) && !vc.isKind(of: WelcomeController.self))
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        ZBFHealthKit.getPermissions()
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }

}


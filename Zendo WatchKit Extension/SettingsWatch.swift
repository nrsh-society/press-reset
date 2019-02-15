//
//  SettingsWatch.swift
//  Zendo WatchKit Extension
//
//  Created by Anton Pavlov on 15/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation


class SettingsWatch  {
    
    static let defaults = UserDefaults.standard
    
    static let dailyMediationGoalKey = "dailyMediationGoal"
    static let sharedUserActivityType = "tools.sunyata.Zendo.app"
    static let sharedIdentifierKey = "identifier"

    
    static var fullName: String? {
        set {
            defaults.set(newValue, forKey: "fullNameWatch")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "fullNameWatch")
        }
    }
    
    static var email: String? {
        set {
            defaults.set(newValue, forKey: "emailWatch")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "emailWatch")
        }
    }
    
    static var localNotications: Bool {
        set {
            defaults.set(newValue, forKey: "requestedNotificationPermission")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "requestedNotificationPermission")
        }
    }
    
    static var dailyMediationGoal: Int {
        set {
            defaults.set(newValue, forKey: dailyMediationGoalKey)
            defaults.synchronize()
        }
        get {
            return defaults.integer(forKey: dailyMediationGoalKey)
        }
    }
    
    static var currentDailyMediationPercent: Int {
        set {
            defaults.set(newValue, forKey: "currentDailyMediationPercent")
            defaults.synchronize()
        }
        get {
            return defaults.integer(forKey: "currentDailyMediationPercent")
        }
    }
    
    static var isFirstSession: Bool {
        set {
            defaults.set(newValue, forKey: "isFirsrSession")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "isFirsrSession")
        }
    }
    
}


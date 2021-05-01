//
//  SettingsWatch.swift
//  Zendo WatchKit Extension
//
//  Created by Anton Pavlov on 15/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation
import HealthKit

class SettingsWatch
{
    static let defaults = UserDefaults.standard
    
    static let dailyMediationGoalKey = "dailyMediationGoal"
        
    static var loggedIn: Bool
    {
        set {
            defaults.set(newValue, forKey: "loggedIn")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "loggedIn")
        }
    }
    
    static var registered: Bool
    {
        set {
            defaults.set(newValue, forKey: "registered")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "registered")
        }
    }
    
    static var appleUserID: String?
    {
        set
        {
            defaults.set(newValue, forKey: "appleUserID")
            defaults.synchronize()
        }
        get
        {
            return defaults.string(forKey: "appleUserID")
        }
    }
    
    static var donatedMinutes: Int
    {
        set
        {
            defaults.set(newValue, forKey: "totalMinsMeditated")
            defaults.synchronize()
        }
        get
        {
            return defaults.integer(forKey: "totalMinsMeditated")
        }
    }
    
    static var progressPosition: String?
    {
        set
        {
            defaults.set(newValue, forKey: "progressPosition")
            defaults.synchronize()
        }
        get
        {
            return defaults.string(forKey: "progressPosition")
        }
    }
    
    static var fullName: String?
    {
        set {
            defaults.set(newValue, forKey: "fullNameWatch")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "fullNameWatch")
        }
    }
    
    static var email: String?
    {
        set {
            defaults.set(newValue, forKey: "emailWatch")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "emailWatch")
        }
    }
    
    static var localNotications: Bool
    {
        set {
            defaults.set(newValue, forKey: "requestedNotificationPermission")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "requestedNotificationPermission")
        }
    }
    
    static var donations: Bool
    {
        set {
            defaults.set(newValue, forKey: "requestedDonationsPermission")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "requestedDonationsPermission")
        }
    }
    
    static var progress: Bool
    {
        set {
            defaults.set(newValue, forKey: "requestedProgressPermission")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "requestedProgressPermission")
        }
    }
    
    static var dailyMediationGoal: Int
    {
        set {
            defaults.set(newValue, forKey: "dailyMediationGoal")
            defaults.synchronize()
        }
        get {
            return defaults.integer(forKey: "dailyMediationGoal")
        }
    }
    
    static var currentDailyMediationPercent: Int
    {
        set {
            defaults.set(newValue, forKey: "currentDailyMediationPercent")
            defaults.synchronize()
        }
        get {
            return defaults.integer(forKey: "currentDailyMediationPercent")
        }
    }
    
    static var isFirstSession: Bool
    {
        set {
            defaults.set(newValue, forKey: "isFirsrSession")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "isFirsrSession")
        }
    }
}

struct Options
{
    var hapticStrength : Int
    {
        get
        {
            if let value = UserDefaults.standard.object(forKey: "hapticStrength")
            {
                return value as! Int
            }
            else
            {
                return 1
            }
        }
        
        set
        {
            UserDefaults.standard.set(newValue, forKey: "hapticStrength")
        }
    }
    
    var retryStrength : Int
    {
        get
        {
            
            if let value = UserDefaults.standard.object(forKey: "retryStrength")
            {
                return value as! Int
            }
            else
            {
                return 1
            }
        }
        
        set
        {
            UserDefaults.standard.set(newValue, forKey: "retryStrength")
        }
    }
    
    
    var saveHRVSamples : Bool
    {
        get
        {
            
            if let value = UserDefaults.standard.object(forKey: "saveHRVSamples")
            {
                return value as! Bool
            }
            else
            {
                return true
            }
        }
        
        set
        {
            UserDefaults.standard.set(newValue, forKey: "saveHRVSamples")
        }
    }
}

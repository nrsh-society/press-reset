//
//  Settings.swift
//  Zendo
//
//  Created by Anton Pavlov on 07/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation


class Settings  {

    static let defaults = UserDefaults.standard

    static var isRunOnce: Bool {
        set {
            defaults.set(newValue, forKey: "runonce")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "runonce")
        }
    }
    
    static var fullName: String? {
        set {
            defaults.set(newValue, forKey: "fullName")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "fullName")
        }
    }
    
    static var email: String? {
        set {
            defaults.set(newValue, forKey: "email")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "email")
        }
    }
    
    static var requestedNotificationPermission: Bool {
        set {
            defaults.set(newValue, forKey: "requestedNotificationPermission")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "requestedNotificationPermission")
        }
    }

}

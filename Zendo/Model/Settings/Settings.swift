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

}

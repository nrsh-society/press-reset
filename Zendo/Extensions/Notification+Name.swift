//
//  Notification+Name.swift
//  Zendo
//
//  Created by Anton Pavlov on 08/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let reloadOverview = Notification.Name("reloadOverview")
    static let reloadActivity = Notification.Name("reloadActivity")
    static let startSession = Notification.Name("startSession")
    static let progress = NSNotification.Name("progress")
    static let sample = NSNotification.Name("sample")
    static let endSession = Notification.Name("endSession")
}

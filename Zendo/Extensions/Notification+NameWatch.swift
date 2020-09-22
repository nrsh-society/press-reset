//
//  Notification+NameWatch.swift
//  Zendo
//
//  Created by Boris Sedov on 17.01.2020.
//  Copyright © 2020 zenbf. All rights reserved.
//
    

import Foundation

extension NSNotification.Name
{
    
    static let startSession = NSNotification.Name("startSession")
    static let progress = NSNotification.Name("progress")
    static let sample = NSNotification.Name("sample")
    static let endSession = NSNotification.Name("endSession")
    
    //
    
    static let endSessionFromiPhone = NSNotification.Name("endSessionFromiPhone")
    
    static let reloadOverview = NSNotification.Name("reloadOverview")
    static let reloadActivity = NSNotification.Name("reloadActivity")
    
}

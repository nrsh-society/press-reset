//
//  TimeZone+UTC.swift
//  Zendo
//
//  Created by Anton Pavlov on 28/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation

extension TimeZone {
    
    static var UTC: TimeZone {
        return TimeZone(abbreviation: "UTC")!
    }
    
}

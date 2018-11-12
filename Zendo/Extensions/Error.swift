//
//  Error.swift
//  Zendo
//
//  Created by Anton Pavlov on 12/11/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation

extension Error {
    var code: Int { return (self as NSError).code }
    var domain: String { return (self as NSError).domain }
}

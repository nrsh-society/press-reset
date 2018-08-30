//
//  String.swift
//  Zendo
//
//  Created by Anton Pavlov on 30/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation

extension String {

    func isEmail() -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$",
                                             options: [.caseInsensitive])
        
        return regex.firstMatch(in: self, options:[],
                                range: NSMakeRange(0, utf16.count)) != nil
    }

}

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
        let regex = try! NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,64}$",
                                             options: [.caseInsensitive])
        
        let trimmed = self.trimmingCharacters(in: .whitespaces)
        
        return regex.firstMatch(in: trimmed, options:[],
                                range: NSMakeRange(0, trimmed.utf16.count)) != nil
    }

}

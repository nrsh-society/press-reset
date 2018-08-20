//
//  Array.swift
//  Zendo
//
//  Created by Anton Pavlov on 20/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    func removingDuplicates() -> Array {
        return reduce(into: []) { result, element in
            if !result.contains(element) {
                result.append(element)
            }
        }
    }
}

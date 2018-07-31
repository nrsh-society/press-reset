//
//  UIFont.swift
//  Zendo
//
//  Created by Anton Pavlov on 31/07/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

extension UIFont {
    
    static func zendo(font: ConstraintFont, size: CGFloat) -> UIFont {
        return UIFont(name: font.rawValue, size: size)!
    }
    
}

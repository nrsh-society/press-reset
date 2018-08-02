//
//  UIView.swift
//  Zendo
//
//  Created by Anton Pavlov on 02/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

extension UIView {
    
    func setShadowView() {
        layer.cornerRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowColor = UIColor(red:0.73, green:0.73, blue:0.73, alpha:0.2).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 10
    }
}

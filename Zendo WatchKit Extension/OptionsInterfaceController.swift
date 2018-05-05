//
//  OptionsInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 5/3/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import WatchKit
import Foundation

class OptionsInterfaceController : WKInterfaceController {
    
    @IBAction func KyosakChanged(_ value: Float) {
        
        Session.options.hapticStrength = Int(value.rounded())
    }
    
}

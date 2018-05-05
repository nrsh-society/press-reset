//
//  InterfaceController.swift
//  Zazen WatchKit Extension
//
//  Created by Douglas Purdy on 12/27/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import WatchKit
import Foundation

var _currentSession : Session?

class AppInterfaceController: WKInterfaceController {

    
    @IBAction func start() {
        
        NSLog("start press");
        
        startSession();
        
    }
    
    
    func startSession() {

        _currentSession = Session();
        
        _currentSession?.start();
        
        WKInterfaceDevice.current().play(WKHapticType.start)
        
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SessionInterfaceController", context: _currentSession  as AnyObject)
            , (name: "OptionsInterfaceController", context: _currentSession  as AnyObject)])

    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

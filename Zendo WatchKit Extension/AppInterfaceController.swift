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

    @IBAction func onFortyMinuteStartPress() {
        
        NSLog("onFortyMinuteStartPress");
        
        startSession(duration: 40);
    
    }
    
    @IBAction func onThirtyMinuteStartPress() {
        
        NSLog("onThirtyMinuteStartPress");
        
        startSession(duration: 30);
    }
    
    @IBAction func onTwentyMinutesStartPress() {
        
        NSLog("onTwentyMinutesStartPress");
        
        startSession(duration: 20);
    }
    
    @IBAction func onTenMinutesStartPress() {
        
        NSLog("onTenMinutesStartPress");
        
        startSession(duration: 10);
    }
    
    func startSession(duration: Int) {

        _currentSession = Session(duration: duration);
        
        _currentSession?.start();
        
        WKInterfaceDevice.current().play(WKHapticType.start)
        
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SessionInterfaceController", context: _currentSession  as AnyObject)])

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

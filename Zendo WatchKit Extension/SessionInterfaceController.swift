
//
//  TimerInterfaceController.swift
//  Zazen WatchKit Extension
//
//  Created by dmp on 12/29/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import WatchConnectivity

class SessionInterfaceController: WKInterfaceController, SessionDelegate {
    
    var timer: Timer!
    var session: Session!
    
    @IBOutlet var timeElapsedLabel: WKInterfaceLabel!
    
     func sessionTick(startDate: Date) {
        
        DispatchQueue.main.async {
            
            let timeElapsed = Int(abs(startDate.timeIntervalSinceNow / 60).rounded());
            
            var value = timeElapsed.description
            
            if timeElapsed < 10 {
                value = "0\(value)"
            }
        
            self.timeElapsedLabel.setText(value)
    
        }
    }
    
    @IBAction func onDonePress() {
        session.end()
        
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "AppInterfaceController", context: session  as AnyObject), (name: "OptionsInterfaceController", context: session  as AnyObject)])
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if context != nil {
            session = context as? Session
            session.delegate = self
            timeElapsedLabel.setText("00")
        }
    }

    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()

    }

}

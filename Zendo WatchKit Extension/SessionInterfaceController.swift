
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
            
            let timeElapsed = abs(startDate.timeIntervalSinceNow)
        
            self.timeElapsedLabel.setText(timeElapsed.stringZendoTimeWatch)
            
        }
    }
    
    @IBAction func onDonePress() {
        session.end() { workout in
            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SummaryInterfaceController", context: ["session": self.session, "workout": workout] as AnyObject), (name: "OptionsInterfaceController", context: ["session": self.session, "workout": workout] as AnyObject)])
        }
        
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if context != nil {
            session = context as? Session
            session.delegate = self
            timeElapsedLabel.setText("00:00:00")
        }
    }

    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()

    }

}


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
import Mixpanel

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
            DispatchQueue.main.async() {
                Mixpanel.sharedInstance()?.track("stop_session")
                
                WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SummaryInterfaceController", context: ["session": self.session, "workout": workout] as AnyObject)])
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        Mixpanel.sharedInstance()?.track("zazen_screen")
        
        if let context = context as? Session {
            session = context
            session.delegate = self
            timeElapsedLabel.setText("00:00")
        }
    }

    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()

    }

}

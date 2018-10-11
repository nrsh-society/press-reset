
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
    
    @IBOutlet var commandImage: WKInterfaceImage!
    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    var timer: Timer!
    var session: Session!
    var heartBeats = [Int()]
    
    @IBOutlet var timeElapsedLabel: WKInterfaceLabel!
    
    func sessionTick(startDate: Date, message: String?)
    {
        DispatchQueue.main.async
        {
            let timeElapsed = abs(startDate.timeIntervalSinceNow)
        
            self.timeElapsedLabel.setText(timeElapsed.stringZendoTimeWatch)
            
            if let message = message
            {
                self.heartRateLabel.setText(message)
            }
        }
    }
    
    @IBAction func onDonePress() {
        session.end() { workout in
            DispatchQueue.main.async() {
                Mixpanel.sharedInstance()?.track("watch_meditation")
                
                WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SummaryInterfaceController", context: ["session": self.session, "workout": workout] as AnyObject)])
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        Mixpanel.sharedInstance()?.timeEvent("watch_meditation")
        
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

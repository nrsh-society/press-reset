
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

class SessionInterfaceController: WKInterfaceController, SessionDelegate {
    
    var _timer: Timer!
    var _session: Session!;
    
    @IBOutlet var timeRemainingLabel: WKInterfaceLabel!
    @IBOutlet var timeElapsedLabel: WKInterfaceLabel!
    
     func sessionTick(startDate: Date, endDate: Date) {
        
        DispatchQueue.main.async {
        
            let timeRemaining = Int((endDate.timeIntervalSinceNow / 60).rounded());
            let timeElapsed = Int(abs(startDate.timeIntervalSinceNow / 60).rounded());
        
            self.timeRemainingLabel.setText(timeRemaining.description);
            self.timeElapsedLabel.setText(timeElapsed.description)
            
        }
        
    }
    
    @IBAction func onDonePress() {
        
        _session.end();
        
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "AppInterfaceController", context: NSNull())])
    }
    
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
        
        if(context != nil) {
        
            _session = context as! Session;
            
            _session.delegate = self;
            
            let minutesRemaining = _session.duration / 60;
            
            timeRemainingLabel.setText(minutesRemaining.description);
            timeElapsedLabel.setText("0")
            
        }
    }

    override func willActivate() {
        
        super.willActivate()
    }
    
    override func didDeactivate() {
    
        super.didDeactivate()

    }

}

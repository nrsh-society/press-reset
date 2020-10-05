
//
//  TimerInterfaceController.swift
//  Zazen WatchKit Extension
//
//  Created by dmp on 12/29/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import Parse
import Mixpanel
import WatchKit
import HealthKit
import Foundation
import WatchConnectivity

class SessionInterfaceController: WKInterfaceController, SessionDelegate
{
    var session: Session!
    
    @IBOutlet var heartRateLabel: WKInterfaceLabel!
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
    
    @IBAction func onDonePress()
    {
        endSession()
    }
    
    @objc func endSessionFromiPhone()
    {
        endSession()
    }
    
    func endSession()
    {
        session.end()
        {
            [weak self] workout in
            
            guard let self = self else { return }
                        
            DispatchQueue.main.async()
            {
                if let workout = workout
                {
                    Mixpanel.sharedInstance()?.track("watch_meditation")
                    
                    WKInterfaceController.reloadRootControllers(withNamesAndContexts:
                                                                    [(name: "SummaryInterfaceController",
                                                                      context: ["session": self.session,
                                                                            "workout": workout] as AnyObject)])
                }
                else
                {
                    let ok = WKAlertAction(title: "OK", style: .default)
                    {
                        ExtensionDelegate.openUrl(urlString: "x-apple-health://")
                        
                        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "AppInterfaceController", context: self.session as AnyObject), (name: "SetGoalInterfaceController", context: false as AnyObject), (name: "OptionsInterfaceController", context: self.session as AnyObject)])
                    }
                    
                    self.presentAlert(withTitle: nil, message: "Error saving data. Zendō needs access to Apple Health. Nothing is shared with us or anyone else without your permission.", preferredStyle: .alert, actions: [ok])
                                        
                }
            }
        }
    }
    
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        
        Mixpanel.sharedInstance()?.timeEvent("watch_meditation")
        
        if let context = context as? Session {
            session = context
            session.delegate = self
            timeElapsedLabel.setText("00:00")
        }
        
    }
    
    override func willActivate()
    {
        super.willActivate()
        
    }

    override func didDeactivate()
    {
        super.didDeactivate()
    }
    
}

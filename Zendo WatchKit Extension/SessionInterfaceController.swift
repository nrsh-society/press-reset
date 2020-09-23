
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
import Parse

class SessionInterfaceController: WKInterfaceController, SessionDelegate {

    var timer: Timer!
    var session: Session!
    var heartBeats = [Int()]
    
    @IBOutlet var commandImage: WKInterfaceImage!
    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    @IBOutlet var timeElapsedLabel: WKInterfaceLabel!
    
    private lazy var sessionDelegater: SessionDelegater = { return SessionDelegater() }()
    
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
    
    func openUrl(urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        
        NSExtensionContext().open(url)
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
            
            self.sessionDelegater.sendMessage(["watch": "end"],
                                         replyHandler: nil,
                                         errorHandler: nil)
            
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
                    SettingsWatch.checkAuthorizationStatus
                    {
                        [weak self] success in
                        
                        guard let self = self else { return }
                        
                        if success {
                            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "AppInterfaceController", context: self.session as AnyObject), (name: "SetGoalInterfaceController", context: false as AnyObject), (name: "OptionsInterfaceController", context: self.session as AnyObject)])
                        } else {
                            let ok = WKAlertAction(title: "OK", style: .default)
                            {
                                
                                self.openUrl(urlString: "x-apple-health://")
                                
                                WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "AppInterfaceController", context: self.session as AnyObject), (name: "SetGoalInterfaceController", context: false as AnyObject), (name: "OptionsInterfaceController", context: self.session as AnyObject)])
                            }
                            
                            self.presentAlert(withTitle: nil, message: "Error saving data. Zendō needs access to Apple Health to measure and record metrics during meditation. All Health data remains on your devices, nothing is shared with us or anyone else without your permission.", preferredStyle: .alert, actions: [ok])
                        }
                    }
                                        
                }
                
            }
        }
    }
    
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        
        Mixpanel.sharedInstance()?.timeEvent("watch_meditation")
        
        sessionDelegater.sendMessage(["facebook" : "watch_meditation"],
                                     replyHandler: nil, errorHandler: nil)
        
        if let context = context as? Session {
            session = context
            session.delegate = self
            timeElapsedLabel.setText("00:00")
        }
        
        if SettingsWatch.appleUserID != nil
        {
            PFUser.logInWithUsername(inBackground: SettingsWatch.email!, password: SettingsWatch.email!)
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progress),
                                               name:  .progress,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(endSessionFromiPhone),
                                               name:  .endSessionFromiPhone,
                                               object: nil)
    
    }
    
    override func willActivate()
    {
        super.willActivate()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func didDeactivate()
    {
        super.didDeactivate()
    }
    
    @objc func progress(notification: NSNotification)
    {
        if (notification.object as? String) != nil
        {
            DispatchQueue.main.async
            {                
                if(SettingsWatch.donations)
                {
                    SettingsWatch.donatedMinutes += 1
                    
                        PFCloud.callFunction(inBackground: "donate",
                                             withParameters: ["id": SettingsWatch.email as Any, "donatedMinutes": SettingsWatch.donatedMinutes])
                        {
                            (response, error) in

                            if let error = error
                            {
                                print(error)
                            }
                        }
                }
            
                if(SettingsWatch.progress)
                {
                    
                        PFCloud.callFunction(inBackground: "rank",
                                             withParameters: ["id": SettingsWatch.email as Any, "donatedMinutes": SettingsWatch.donatedMinutes ])
                        {
                            (response, error) in

                            if let error = error
                            {
                                print(error)
                            }
                            else
                            {
                                if let rank = response as? String
                                {
                                    SettingsWatch.progressPosition = rank
                                }
                            }
                        }
                }
            }
        }
    }
}

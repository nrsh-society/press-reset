
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
import AVFAudio
import AVFoundation

class SessionInterfaceController: WKInterfaceController, SessionDelegate, WKCrownDelegate {
    
    @IBOutlet var commandImage: WKInterfaceImage!
    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    var timer: Timer!
    var session: Session!
    var heartBeats = [Int()]
    
    var countdownDuration: TimeInterval = 0 // Duration in seconds
    var countdownTimer: Timer?
    
    
    func startSessionWithDuration(minutes: Int) {
        countdownDuration = TimeInterval(minutes * 60) // Convert minutes to seconds
        let timeString = self.formatTime(for: self.countdownDuration)
        self.timeElapsedLabel.setText(timeString)
    
    }



    private func updateTimeElapsedLabel() {
        let timeString = formatTime(for: countdownDuration)
        self.timeElapsedLabel.setText(timeString)
    }

    private func formatTime(for duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    @IBOutlet var timeElapsedLabel: WKInterfaceLabel!
    
    @IBOutlet weak var volumeControl: WKInterfaceVolumeControl!
    
    private lazy var sessionDelegater: SessionDelegater = { return SessionDelegater() }()
    
    func crownDidRotate(
        _ crownSequencer: WKCrownSequencer?,
        rotationalDelta: Double
    ) {
        volumeControl.setHidden(true)
        volumeControl.focus()
    }
    
    func crownDidBecomeIdle(_ crownSequencer: WKCrownSequencer?)
    {
        volumeControl.setHidden(true)
    }
        
    func sessionTick(startDate: Date, message: String?, status: Status)
    {
        DispatchQueue.main.async
        {
            let timeElapsed = abs(startDate.timeIntervalSinceNow)
            
            self.countdownDuration -= 1
            
            if(self.countdownDuration > 0 ) {
                let timeString = self.formatTime(for: self.countdownDuration)
                self.timeElapsedLabel.setText(timeString)
            } else {
                self.onDonePress()
            }
            
            if let message = message
            {
                self.heartRateLabel.setText(message)
            }
            
            if(Int(startDate.timeIntervalSinceNow) % 60 == 0) {
                
                
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
    
    @objc func endSessionFromiPhone() {
        endSession()
    }
    
    func endSession()
    {
        
        if(Session.options.audioFeedbackEnabled)
        {
            AudioFeedback.stop()
        }
        
        session.end()
        {
            [weak self] workout in
            
            guard let self = self else { return }
            
            DispatchQueue.main.async()
            {
                if let workout = workout
                {
                    Mixpanel.mainInstance().track(event: "watch_meditation")
                    
                    self.sessionDelegater.sendMessage(["watch" : "endSession"], replyHandler: nil, errorHandler: nil)
                    
                    WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SummaryInterfaceController", context: ["session": self.session, "workout": workout] as AnyObject)])
                } else {
                    
                    
                    ZBFHealthKit.getPermissions()
                    {
                        [weak self] success, error in
                        
                        guard let self = self else { return }
                        
                        if success {
                            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "AppInterfaceController", context: self.session as AnyObject), (name: "OptionsInterfaceController", context: self.session as AnyObject)])
                        } else {
                            let ok = WKAlertAction(title: "OK", style: .default)
                            {
                                
                                self.openUrl(urlString: "x-apple-health://")
                                
                                WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "AppInterfaceController", context: self.session as AnyObject), (name: "OptionsInterfaceController", context: self.session as AnyObject)])
                            }
                            
                            self.presentAlert(withTitle: nil, message: "Error saving data. Press Reset needs access to Apple Health to measure and record metrics during meditation. All Health data remains on your devices, nothing is shared with us or anyone else without your permission.", preferredStyle: .alert, actions: [ok])
                        }
                    }
                                        
                }
                
            }
        }
    }
    
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        
        Mixpanel.mainInstance().time(event: "watch_meditation")
            
        if let context = context as? Session {
            session = context
            session.delegate = self
            //timeElapsedLabel.setText("00:00")
            self.startSessionWithDuration(minutes: SettingsWatch.dailyMediationGoal)
        }
        
        self.crownSequencer.delegate = self
        
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(endSessionFromiPhone),
                                               name:  .endSessionFromiPhone,
                                               object: nil)
        
    }

    override func willActivate() {
        super.willActivate()
        
        if(Session.options.audioFeedbackEnabled)
        {
            AudioFeedback.play()
        }
        
        self.crownSequencer.focus()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
}

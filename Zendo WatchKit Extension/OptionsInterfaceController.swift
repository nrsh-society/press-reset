//
//  OptionsInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 5/3/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import WatchKit
import Foundation
import UIKit
import Mixpanel
import AuthenticationServices

class OptionsInterfaceController : WKInterfaceController, BluetoothManagerStatusDelegate, ASAuthorizationControllerDelegate
{
    //#todo(@State)
    var signedIn : Bool?
    @IBOutlet weak var authorizationButton: WKInterfaceAuthorizationAppleIDButton!
    @IBOutlet weak var signinLabel: WKInterfaceLabel!
    
    //progress
    @IBOutlet weak var progressSwitch: WKInterfaceSwitch!
    @IBOutlet weak var progressLabel: WKInterfaceLabel!
    @IBOutlet weak var progressMetricGroup: WKInterfaceGroup!
    @IBOutlet weak var progressMetricValue: WKInterfaceLabel!
   
    //cause
    @IBOutlet weak var donateSwitch: WKInterfaceSwitch!
    @IBOutlet weak var donateLabel: WKInterfaceLabel!
    @IBOutlet weak var donateMetricGroup: WKInterfaceGroup!
    @IBOutlet weak var donateMetricValue: WKInterfaceLabel!
    
    @IBAction func donationsAction(value: Bool)
    {
        SettingsWatch.donations = value
        donateMetricGroup.setHidden(!value)
        donateLabel.setHidden(value)
        donateMetricValue.setText(SettingsWatch.donatedMinutes.description)
    }
    
    @IBAction func progressAction(value: Bool)
    {
        SettingsWatch.progress = value
        progressMetricGroup.setHidden(!value)
        progressLabel.setHidden(value)
        
        if let value = SettingsWatch.progressPosition
        {
            //this has to be the dumbest line of codes i have written
            if (value.count  > 0)
            {
                progressMetricValue.setText(SettingsWatch.progressPosition)
            }
        }
    }
    
    @IBAction func onAppleSignButtonPressed()
    {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        
        authorizationController.performRequests()
    }
    
    
    @objc func sample(notification: NSNotification)
    {
        if let sample = notification.object as? [String : Any]
        {
            let donatedString = sample["donated"] as? String
            let progressString = sample["progress"] as? String ?? "--/--"
            
            DispatchQueue.main.async
            {
                self.donateMetricValue.setText(donatedString)
                self.progressMetricValue.setText(progressString)
            }
        }
    }
    
    override func awake(withContext context: Any?)
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sample),
                                               name:  .sample,
                                               object: nil)
    }
    
    override func willActivate()
    {
        super.willActivate()
            
        Mixpanel.sharedInstance()?.timeEvent("watch_options")
               
               if let bluetooth = Session.bluetoothManager
               {   self.bluetoothToogle.setOn(bluetooth.isRunning)
                   Session.bluetoothManager?.statusDelegate = self
                   bluetoothStatus.setText(bluetooth.status)
               }
               
               self.hapticSetting.setValue(Float(Session.options.hapticStrength))
               self.retryFeedbackSlider.setValue(Float(Session.options.retryStrength))
              
        
        let isSignedIn = (SettingsWatch.appleUserID != nil)
        
        if isSignedIn
        {
            self.authorizationButton.setHidden(true)
            self.signinLabel.setHidden(true)
            
            self.donateSwitch.setEnabled(true)
            self.progressSwitch.setEnabled(true)
            
            self.donateSwitch.setOn(SettingsWatch.donations)
            self.progressSwitch.setOn(SettingsWatch.progress)
    
            donationsAction(value: SettingsWatch.donations)
            progressAction(value: SettingsWatch.progress)
            
        }
        
 
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization)
    {
        switch authorization.credential
        {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
            
                let userIdentifier = appleIDCredential.user
                
                if userIdentifier == SettingsWatch.appleUserID {
                    
                    self.animate(withDuration: 1, animations: {
                        self.authorizationButton.setHidden(true)
                        self.signinLabel.setHidden(true)
                        
                        self.donateSwitch.setEnabled(true)
                        self.progressSwitch.setEnabled(true)
                        
                    })
                }
                
                SettingsWatch.appleUserID = userIdentifier
                SettingsWatch.email = appleIDCredential.email
                
                if let fullName = appleIDCredential.fullName , let email = appleIDCredential.email
                {
                
                    SettingsWatch.fullName =
                        (fullName.givenName ?? "") +
                            "" + (fullName.familyName ?? "")
                    SettingsWatch.email = email.description
                
                    Mixpanel.sharedInstance()?.track("watch_signin", properties: ["email": SettingsWatch.email as Any])
                
                    Mixpanel.sharedInstance()?.identify(SettingsWatch.email!)
                    Mixpanel.sharedInstance()?.people.set(["$email": SettingsWatch.email!])
                    Mixpanel.sharedInstance()?.people.set(["$name": SettingsWatch.fullName!])
                
                    let ok = WKAlertAction(title: "OK", style: .default)
                    {
                                            
                    }
        
                    self.presentAlert(withTitle: nil, message: "Hi \(fullName.givenName ?? "")! Thanks for caring.", preferredStyle: .alert, actions: [ok])
                }
                
            break
                
        default:
            print("if you are seeing this it is too late")
            
            //but we are going to hyjack this for the demo videos\
        
            self.animate(withDuration: 1, animations: {
                
                self.authorizationButton.setHidden(true)
                self.signinLabel.setHidden(true)
                
                self.donateSwitch.setEnabled(true)
                self.progressSwitch.setEnabled(true)
                
            })
        
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error)
    {
        //but we are going to hyjack this for the demo videos\
    /*
        self.animate(withDuration: 1, animations: {
            
            self.authorizationButton.setHidden(true)
            self.signinLabel.setHidden(true)
            
            self.donateSwitch.setEnabled(true)
            self.progressSwitch.setEnabled(true)
            
        })*/
        
            let ok = WKAlertAction(title: "OK", style: .default)
            {
                
            }
        
            self.presentAlert(withTitle: nil, message: "Error signing in. Zendō uses Apple Sign in for secure access. Nothing is shared without your permission.", preferredStyle: .alert, actions: [ok])
    }
    
    @IBOutlet var bluetoothStatus: WKInterfaceLabel!
    @IBOutlet var hapticSetting: WKInterfaceSlider!
    @IBOutlet var bluetoothToogle: WKInterfaceSwitch!
    
    @IBOutlet var retryFeedbackSlider: WKInterfaceSlider!
    
    
    
    @IBAction func KyosakChanged(_ value: Float)
    {
        Mixpanel.sharedInstance()?.track("watch_options_haptic", properties: ["value": value])
        
        Session.options.hapticStrength = Int(value)
                
        let iterations = Int(Session.options.hapticStrength)
        
        if iterations > 0
        {
            Thread.detachNewThread
                {
                    for _ in 1...iterations
                    {
                        DispatchQueue.main.async
                            {
                                WKInterfaceDevice.current().play(WKHapticType.success)
                        }
                        
                        Thread.sleep(forTimeInterval: 1)
                    }
            }
        }
    }
    
    @IBAction func retryChanged(_ value: Float)
    {
        Mixpanel.sharedInstance()?.track("watch_options_haptic", properties: ["value": value])
        
        Session.options.retryStrength = Int(value)
                
        let iterations = Int(Session.options.retryStrength)
        
        if iterations > 0
        {
            Thread.detachNewThread
                {
                    for _ in 1...iterations
                    {
                        DispatchQueue.main.async
                            {
                                WKInterfaceDevice.current().play(WKHapticType.retry)
                        }
                        
                        Thread.sleep(forTimeInterval: 1)
                    }
            }
        }
    }
    
    @IBAction func bluetoothChanged(_ value: Bool)
    {
        Mixpanel.sharedInstance()?.track("watch_options_bluetooth", properties: ["value": value])
        
        if(value)
        {
            Session.bluetoothManager = BluetoothManager()
            Session.bluetoothManager?.statusDelegate = self
            Session.bluetoothManager?.start()
        }
        else
        {
            Session.bluetoothManager?.end()
            Session.bluetoothManager = nil
            bluetoothStatus.setText("")
        }
    }
    
    func statusUpdated(_ status: String)
    {
        DispatchQueue.main.async
        {
            self.bluetoothStatus.setText(status)
        }
    }
    
   
    override func didDeactivate()
    {
        super.didDeactivate()
        
        Mixpanel.sharedInstance()?.track("watch_options")
    }
    
}

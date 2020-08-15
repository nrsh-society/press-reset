//
//  LabInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Doug Purdy on 4/27/20.
//  Copyright © 2020 zenbf. All rights reserved.
//

import Foundation
import UIKit
import Contacts
import WatchKit
import AuthenticationServices
import Mixpanel

class LabInterfaceController : WKInterfaceController, ASAuthorizationControllerDelegate
{
    
    //signin: @State
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
        donateMetricGroup.setHidden(value)
        donateLabel.setHidden(!value)
        donateMetricValue.setText(SettingsWatch.donatedMinutes.description)
    }
    
    @IBAction func progressAction(value: Bool)
    {
        SettingsWatch.progress = value
        progressMetricGroup.setHidden(value)
        progressLabel.setHidden(!value)
        progressMetricValue.setText(SettingsWatch.progressPosition.description)
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
    
    override func willDisappear() {
        
        Mixpanel.sharedInstance()?.track("watch_lab")
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
        Mixpanel.sharedInstance()?.timeEvent("watch_lab")
        
        let isSignedIn = (SettingsWatch.appleUserID != nil)
        
        if isSignedIn
        {
            self.authorizationButton.setHidden(true)
            self.signinLabel.setHidden(true)
    
            self.donateMetricGroup.setHidden(false)
            self.progressMetricGroup.setHidden(false)
            
            self.donateSwitch.setEnabled(true)
            self.donateSwitch.setOn(SettingsWatch.donations)
            self.progressSwitch.setEnabled(true)
            self.progressSwitch.setOn(SettingsWatch.progress)
                    
        }
        else
        {
            self.authorizationButton.setHidden(false)
            self.signinLabel.setHidden(false)
            
            self.donateMetricGroup.setHidden(true)
            self.progressMetricGroup.setHidden(true)
        }
        
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization)
    {
        switch authorization.credential
        {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
            
                let userIdentifier = appleIDCredential.user
                
                if userIdentifier == SettingsWatch.appleUserID {
                    
                    self.authorizationButton.setHidden(true)
                    self.signinLabel.setHidden(true)
                    
                    self.donateSwitch.setEnabled(true)
                    self.donateSwitch.setOn(SettingsWatch.donations)
                    self.progressSwitch.setEnabled(true)
                    self.progressSwitch.setOn(SettingsWatch.progress)
                    
                    
                }
                
                SettingsWatch.appleUserID = userIdentifier
                
                if let fullName = appleIDCredential.fullName , let email = appleIDCredential.email
                {
                
                    SettingsWatch.fullName =  (fullName.givenName ?? "") + "" + (fullName.familyName ?? "")
                    SettingsWatch.email = email.description
                
                    Mixpanel.sharedInstance()?.track("watch_signin", properties: ["email": SettingsWatch.email as Any])
                
                    Mixpanel.sharedInstance()?.identify(SettingsWatch.email!)
                    Mixpanel.sharedInstance()?.people.set(["$email": SettingsWatch.email!])
                    Mixpanel.sharedInstance()?.people.set(["$name": SettingsWatch.fullName!])
                
                    let ok = WKAlertAction(title: "OK", style: .default)
                    {
                    
                        self.donateSwitch.setEnabled(true)
                        self.donateSwitch.setOn(true)
                        self.progressSwitch.setEnabled(true)
                        self.progressSwitch.setOn(true)
                        self.authorizationButton.setHidden(true)
                        self.signinLabel.setHidden(true)
                        
                    }
        
                    self.presentAlert(withTitle: nil, message: "Hi \(fullName.givenName ?? "")! We are sending instructions to \(email.description ) as fast as we can. Welcome.", preferredStyle: .alert, actions: [ok])
                }
                
            break
                
        default:
            print("if you are seeing this it is too late")
        
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error)
    {
            let ok = WKAlertAction(title: "OK", style: .default)
            {
                
            }
        
            self.presentAlert(withTitle: nil, message: "Error signing in to Labs. Zendō uses Apple Sign in for secure access to causes + community. Nothing is shared without your permission.", preferredStyle: .alert, actions: [ok])
    }
    
    
    //for when we ask for friends on the watch, we are going to do it on the phone for now
    
    func checkForContactsAccess(andThen f:(()->())? = nil) {
        let status = CNContactStore.authorizationStatus(for:.contacts)
        switch status {
        case .authorized:
            f?()
        case .notDetermined:
            CNContactStore().requestAccess(for:.contacts) { ok, err in
                if ok {
                    DispatchQueue.main.async {
                        f?()
                    }
                }
            }
        case .restricted:
            // do nothing
            break
        case .denied:
            // do nothing, or beg the user to authorize us in Settings
            print("denied")
            break
        @unknown default: fatalError()
        }
    }
}

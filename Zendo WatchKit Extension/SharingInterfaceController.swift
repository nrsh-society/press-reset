//
//  SharingInterfaceController.swift
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


class SharingInterfaceController : WKInterfaceController, ASAuthorizationControllerDelegate
{

    
    @IBOutlet weak var authorizationButton: WKInterfaceAuthorizationAppleIDButton!
    
    @IBOutlet weak var donateSwitch: WKInterfaceSwitch!
    @IBOutlet weak var progressSwitch: WKInterfaceSwitch!
    @IBOutlet weak var signinLabel: WKInterfaceLabel!
    
    @IBAction func donationsAction(value: Bool)
    {
        SettingsWatch.donations = value
    }
    
    @IBAction func progressAction(value: Bool)
    {
        SettingsWatch.progress = value
    }
    
    override func willActivate()
    {
        if SettingsWatch.appleUserID == nil
        {
            self.authorizationButton.setHidden(false)
            self.signinLabel.setHidden(false)
            
            self.donateSwitch.setEnabled(false)
            self.donateSwitch.setOn(false)
            self.progressSwitch.setEnabled(false)
            self.progressSwitch.setOn(false)
        }
        else
        {
            self.authorizationButton.setHidden(true)
            self.signinLabel.setHidden(true)
            
            self.donateSwitch.setEnabled(true)
            self.donateSwitch.setOn(SettingsWatch.donations)
            self.progressSwitch.setEnabled(true)
            self.progressSwitch.setOn(SettingsWatch.progress)
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
                    
                    return
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
        
                    self.presentAlert(withTitle: nil, message: "Hi \(fullName.givenName ?? "")! If you already have the Zendō iOS app, open the Labs story in the Discovery tab. Otherwise, we are sending \(email.description ) instructions as fast as we can.", preferredStyle: .alert, actions: [ok])
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
        
            self.presentAlert(withTitle: nil, message: "Error signing up for Labs. Zendō uses Apple Sign in for secure access to donations + community. Nothing is shared without your permission.", preferredStyle: .alert, actions: [ok])
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

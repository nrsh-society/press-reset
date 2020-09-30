//
//  OptionsInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 5/3/18.
//  Copyright © 2018 zenbf. All rights reserved.
//
import Parse
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
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    @IBAction func donationsAction(value: Bool)
    {
        SettingsWatch.donations = value
        donateMetricGroup.setHidden(!value)
        donateLabel.setHidden(value)
        
        if let user = PFUser.current()
        {
            self.donateMetricValue.setText((user["donatedMinutes"] ?? "--") as? String)
        }
        else
        {
            donateMetricValue.setText(SettingsWatch.donatedMinutes.description)
        }
    }
    
    @IBAction func progressAction(value: Bool)
    {
        SettingsWatch.progress = value
        progressMetricGroup.setHidden(!value)
        progressLabel.setHidden(value)
        
        if let user = PFUser.current()
        {
            progressMetricValue.setText((user["progressPosition"] ?? "--") as? String)
        }
        else
        {
            progressMetricValue.setText(SettingsWatch.progressPosition)
        }
    }
    
    @IBAction func onAppleSignButtonPressed()
    {
        Mixpanel.sharedInstance()?.timeEvent("watch_signin")
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        
        authorizationController.performRequests()
    }
    
    
    @objc func progress(notification: NSNotification)
    {
        if let user = PFUser.current()
        {
            let donatedString = (user["donatedMinutes"] ?? "--") as? String
            let progressString = (user["progressPosition"] ?? "-/-") as? String
            
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
                                               selector: #selector(self.progress),
                                               name:  .progress,
                                               object: nil)
    }
    
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didDeactivate()
    {
        super.didDeactivate()
        
        Mixpanel.sharedInstance()?.track("watch_options")
        
    }
    
    override func willActivate()
    {
        super.willActivate()
            
        Mixpanel.sharedInstance()?.timeEvent("watch_options")
               
        if let user = PFUser.current()
        {
            self.hapticSetting.setValue(Float(Session.options.hapticStrength))
            
            self.authorizationButton.setHidden(true)
            self.signinLabel.setHidden(true)
            
            self.donateSwitch.setEnabled(true)
            self.progressSwitch.setEnabled(true)
            
            let donations = (user["donations"] ?? false) as! Bool
            let progress = (user["progress"] ?? false) as! Bool
            
            donationsAction(value: donations)
            progressAction(value: progress)
            
            let donatedString = (user["donatedMinutes"] ?? "--") as? String
            let progressString = (user["progressPosition"] ?? "-/-") as? String

            self.donateMetricValue.setText(donatedString)
            self.progressMetricValue.setText(progressString)

        }
        
        //#todo(7): merge with zensor too
        if let bluetooth = Session.bluetoothManager
        {
            self.bluetoothToogle.setOn(bluetooth.isRunning)
            Session.bluetoothManager?.statusDelegate = self
            bluetoothStatus.setText(bluetooth.status)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization)
    {
        
        switch authorization.credential
        {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
            
                let userIdentifier = appleIDCredential.user
                
                //#backward-compat: this was someone that logged in before we added the backend
                if userIdentifier == SettingsWatch.appleUserID
                {
                    self.animate(withDuration: 1, animations:
                    {
                        self.authorizationButton.setHidden(true)
                        self.signinLabel.setHidden(true)
                        
                        self.donateSwitch.setOn(SettingsWatch.donations)
                        self.progressSwitch.setOn(SettingsWatch.progress)
                
                        self.donationsAction(value: SettingsWatch.donations)
                        self.progressAction(value: SettingsWatch.progress)
                     
                    })
                    
                    Mixpanel.sharedInstance()?.track("watch_signin_upgrade", properties: ["email": SettingsWatch.email as Any])
                }
                else
                {
                    SettingsWatch.appleUserID = userIdentifier
                }
               
                if let fullName = appleIDCredential.fullName , let email = appleIDCredential.email
                {
                    //#backward-compat: support this until 7.0?
                    SettingsWatch.fullName =
                        (fullName.givenName ?? "") +
                            " " + (fullName.familyName ?? "")
                    SettingsWatch.email = email.description
                
                    Mixpanel.sharedInstance()?.identify(SettingsWatch.email!)
                    Mixpanel.sharedInstance()?.people.set(["$email": SettingsWatch.email!])
                    Mixpanel.sharedInstance()?.people.set(["$name": SettingsWatch.fullName!])
                    Mixpanel.sharedInstance()?.people.set(["$appleid": SettingsWatch.appleUserID!])
            
                    let user = PFUser()
                    user.username = userIdentifier
                    user.password = String(userIdentifier.prefix(9))
                    user.email = email.description
                    user["fullname"] = (fullName.givenName ?? "") +
                        " " + (fullName.familyName ?? "")
                    user["donatedMinutes"] = 0
                    user["progressPosition"] = "-/-"
                    user["donations"] = SettingsWatch.donations //backward compat
                    user["progress"] = SettingsWatch.progress //backward compat
                
                    user.signUpInBackground
                    {
                        (succeeded, error) in
                        
                        if let error = error
                        {
                            print(error.localizedDescription)
                            
                        }
                    }
                
                  
                    let ok = WKAlertAction(title: "OK", style: .default)
                    {
                        Mixpanel.sharedInstance()?.track("watch_signin")
                    }
        
                    self.presentAlert(withTitle: nil, message: "Hi \(fullName.givenName ?? "")! Thanks for caring.", preferredStyle: .alert, actions: [ok])
                }
                
            break
                
        default:
            print("if you are seeing this it is too late")
            
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error)
    {

        let ok = WKAlertAction(title: "OK", style: .default) {
            
            Mixpanel.sharedInstance()?.track("watch_signin", properties: ["email": SettingsWatch.email as Any])
        }
        
        self.presentAlert(withTitle: nil, message: "Error signing in. Zendō uses Apple Sign in for secure access. Nothing is shared without your permission.", preferredStyle: .alert, actions: [ok])
    }
    
    @IBOutlet var bluetoothStatus: WKInterfaceLabel!
    @IBOutlet var hapticSetting: WKInterfaceSlider!
    @IBOutlet var bluetoothToogle: WKInterfaceSwitch!
        
    @IBAction func KyosakChanged(_ value: Float)
    {
        Mixpanel.sharedInstance()?.track("watch_options_haptic", properties: ["value": value])
        
        Session.options.hapticStrength = Int(value)
        Session.options.retryStrength = Int(value)
                
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
    
}

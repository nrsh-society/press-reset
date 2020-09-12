//
//  WatchSyncError.swift
//  Zendo
//
//  Created by Egor Privalov on 06/11/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Mixpanel
import WatchConnectivity
import CoreBluetooth


enum ErrorConfiguration {
    case connecting, success, noInstallZendo, needWear, noAppleWatch, unableToDetect
    
    var image: UIImage? {
        switch self {
        case .connecting: return UIImage(named: "watchConnect")
        case .success: return UIImage(named: "watchConnectSuccess")
        case .noInstallZendo: return UIImage(named: "watchConnectInstall")
        case .needWear: return UIImage(named: "watchNotOnWrist")
        case .noAppleWatch: return UIImage(named: "watchConnectNonePaired")
        case .unableToDetect: return UIImage(named: "watchConnect")
        }
    }
    
    var zenButton: (isHidden: Bool, text: String) {
        switch self {
        case .connecting: return (true, "")
        case .success: return (false, "Get Started")
        case .noInstallZendo: return (false, "Go to Watch App")
        case .needWear: return (false, "Retry")
        case .noAppleWatch: return (false, "Done")
        case .unableToDetect: return (false, "Done")
        }
    }
    
    var text: [String] {
        switch self {
        case .connecting: return [
            "connecting to",
            "Apple Watch",
            "Checking to see if Apple Watch is paired with iPhone."
            ]
        case .success: return [
            "watch setup",
            "complete",
            "Successfully connected to Apple Watch. Use your watch to monitor your HRV and record meditation sessions."
            ]
        case .noInstallZendo: return [
            "install zendō",
            "watch app",
            """
            Zendō needs to be installed on Apple Watch.
            
            1.  Go to Watch App
            2.  Locate Zendō and tap Install
            """
            ]
        case .needWear: return [
            "wear your",
            "Apple Watch",
            "In order start a meditation session, you need to wear Apple Watch. Wear your watch and try again."
            ]
        case .noAppleWatch: return [
            "no Apple Watch",
            "paired to phone",
            "In order to record a meditation session and track your HRV, Zendō requires Apple Watch."
            ]
        case .unableToDetect: return [
            "unable to detect",
            "Apple Watch",
            "Make sure Apple Watch is connected to iPhone."
            ]
        }
    }
}

class WatchSyncError: HealthKitViewController {
    
    var errorConfiguration = ErrorConfiguration.connecting
    var isFirstCheck = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setScreen()
        
        zenButton.action = {
            if WCSession.isSupported() {
                switch self.errorConfiguration {
                case .noAppleWatch:
                   //let session = WCSession.default
                    
                    //if session.isPaired {
                        self.dismiss(animated: true)
                    //}
                case .noInstallZendo:
                    //#todo(appl)
                    if let url = URL(string: "itms-watch://") {
                        self.dismiss(animated: true) {
                            UIApplication.shared.open(url)
                        }
                    } else if let url = URL(string: "itms-watchs://") {
                        self.dismiss(animated: true) {
                            UIApplication.shared.open(url)
                        }
                    } else {
                        self.dismiss(animated: true)
                    }
                case .success:
                    self.dismiss(animated: true)
                case .needWear, .unableToDetect:
                    if self.isFirstCheck {
                        self.errorConfiguration = .connecting
                        self.setScreen()
                        self.check()
                    } else {
                        self.dismiss(animated: true)
                    }
                default: break
                }
                
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        check()
    }
    
    func check() {
        //let peripheral = CBCentralManager().retrieveConnectedPeripherals(withServices: [CBUUID(string: "180A")])
        
        
        if let topVC = UIApplication.topViewController() as? WatchSyncError {
            
            if topVC.errorConfiguration == .noInstallZendo && WCSession.default.isWatchAppInstalled && isFirstCheck {
                errorConfiguration = .connecting
            }
            
            //if topVC.errorConfiguration == .unableToDetect && !peripheral.isEmpty && isFirstCheck {
              //  errorConfiguration = .connecting
            //}
            
            
            if topVC.errorConfiguration == .connecting && WCSession.isSupported() {
                let session = WCSession.default
                
                if !session.isPaired {
                    errorConfiguration = .noAppleWatch
                    setScreen()
                //} //else if peripheral.isEmpty {
                    //errorConfiguration = .unableToDetect
                    //setScreen()
                } else if !session.isWatchAppInstalled {
                    errorConfiguration = .noInstallZendo
                    setScreen()
                } else {
                    errorConfiguration = .success
                    setScreen()
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.mainInstance().time(event: "phone_watch_sync")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        var state = ""
        
        switch self.errorConfiguration
        {
            
            case .noAppleWatch:
                state = "no_apple_watch"
            case .noInstallZendo:
                state = "no_zendo_installed"
            case .success:
                state = "success"
            case .needWear:
                state = "not_wearing"
            case .unableToDetect:
                state = "not_detected"
            default: break
        }
        
        let props = ["state" : state]
        
        Mixpanel.mainInstance().track(event: "phone_watch_sync", properties: props)
    }
    
    override class func loadFromStoryboard() -> WatchSyncError {
        let storyboard =  UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HealthKitViewController") as! HealthKitViewController
        object_setClass(storyboard, WatchSyncError.self)
        return storyboard as! WatchSyncError
    }
    
    func setScreen() {
        for label in labels {
            switch label.tag {
            case 0: label.text = errorConfiguration.text[0]
            case 1: label.text = errorConfiguration.text[1]
            case 2: label.text = errorConfiguration.text[2]
            
            label.attributedText = setAttributedString(label.text ?? "")
            default: break
            }
        }
        
        image.image = errorConfiguration.image
        zenButton.isHidden = errorConfiguration.zenButton.isHidden
        zenButton.title.text = errorConfiguration.zenButton.text
    }
    
}


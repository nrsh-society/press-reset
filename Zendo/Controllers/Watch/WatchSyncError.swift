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


enum ErrorConfiguration {
    case connecting, settingUp, noInstallZendo, needWear, noAppleWatch
    
    var image: UIImage? {
        switch self {
        case .connecting: return UIImage(named: "watchConnect")
        case .settingUp: return UIImage(named: "watchConnectSuccess")
        case .noInstallZendo: return UIImage(named: "watchConnectInstall")
        case .needWear: return UIImage(named: "watchNotOnWrist")
        case .noAppleWatch: return UIImage(named: "watchConnectNonePaired")
        }
    }
    
    var zenButton: (isHidden: Bool, text: String) {
        switch self {
        case .connecting: return (true, "")
        case .settingUp: return (false, "Get Started")
        case .noInstallZendo: return (false, "Go to Watch App")
        case .needWear: return (false, "Back")
        case .noAppleWatch: return (false, "Sync Data")
        }
    }
    
    var text: [String] {
        switch self {
        case .connecting: return [
            "connecting to",
            "Apple Watch…",
            "Checking to see if your watch is paired with your phone."
            ]
        case .settingUp: return [
            "setting up",
            "apple watch",
            "Checking to see if your watch is paired with your phone. One more moment please."
            ]
        case .noInstallZendo: return [
            "install zendō",
            "watch app",
            """
            Zendō Watch App needs to be installed on your Apple Watch.
            
            1.  Go to Watch App
            2.  Locate Zendo and tap Install
            """]
        case .needWear: return [
            "wear your",
            "apple watch",
            """
            In order to record meditation session, you need to wear your Apple Watch.
            """]
        case .noAppleWatch: return [
            "no Apple Watch",
            "paired to phone",
            """
            In order to record a meditation session and track your HRV, Zendo requires a connnected Apple Watch device.
            """]
        }
    }
}

class WatchSyncError: HealthKitViewController {
    
    var errorConfiguration = ErrorConfiguration.connecting
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for label in labels {
            if label.tag == 2 {
                label.font = UIFont.zendo(font: .antennaRegular, size: label.font.pointSize)
                let attributedString = NSMutableAttributedString(string: label.text ?? "")
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineHeightMultiple = 1.43
                
                attributedString.addAttribute(.paragraphStyle, value:paragraphStyle, range: NSMakeRange(0, attributedString.length))
                
                label.attributedText = attributedString
            }
        }
        
        if UIDevice.small {
            for label in labels {
                label.font = UIFont.zendo(font: .antennaRegular, size: label.font.pointSize - 2)
            }
        }
        
        if UIDevice.iPhoneX {
            heightImage.isActive = false
        }
        
        setScreen()
        
        zenButton.action = {
            if WCSession.isSupported() {
                switch self.errorConfiguration {
                case .noAppleWatch:
                    let session = WCSession.default
                    
                    if session.isPaired {
                        self.dismiss(animated: true)
                    }
                case .noInstallZendo:
                    UIApplication.shared.open(URL(string: "itms-watch://")!)
                case .settingUp:
                    self.dismiss(animated: true)
                case .needWear:
                    self.dismiss(animated: true)
                default: break
                }
                
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let topVC = UIApplication.topViewController() as? WatchSyncError {
            
            if topVC.errorConfiguration == .noInstallZendo && WCSession.default.isWatchAppInstalled {
                errorConfiguration = .connecting
            }
            
            if topVC.errorConfiguration == .connecting && WCSession.isSupported() {
                let session = WCSession.default
                
                if !session.isPaired {
                    errorConfiguration = .noAppleWatch
                    setScreen()
                }else if !WCSession.default.isWatchAppInstalled {
                    errorConfiguration = .noInstallZendo
                    setScreen()
                } else {
                    errorConfiguration = .settingUp
                    setScreen()
                }
            }
        }
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.mainInstance().time(event: "WatchSyncError")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "WatchSyncError")
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


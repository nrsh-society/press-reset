//
//  UIViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 09/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Mixpanel

extension UIViewController {
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showInitialController() {
        if let vc = UIApplication.shared.keyWindow?.topViewController {
            if !vc.isKind(of: NavigationControllerWelcome.self) {
                let controller = NavigationControllerWelcome.loadFromStoryboard()
                present(controller, animated: true)
            }
        }
    }
    
    func showNotificationController()
    {
        if let vc = UIApplication.shared.keyWindow?.topViewController {
            if !vc.isKind(of: NotificationViewController.self) {
                let controller = NotificationViewController.loadFromStoryboard()
                present(controller, animated: true)
            }
        }
    }
    
    func checkZoomed() -> Bool {
        return UIScreen.main.nativeScale > UIScreen.main.scale
    }
    
    func showHealthKitController(isFailed: Bool) {
        if isFailed {
            let vc = HealthKitControllerFailed.loadFromStoryboard()
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: true)
        } else {
            let controller = HealthKitViewController.loadFromStoryboard()
            present(controller, animated: true)
        }
    }
    
    func updateOverview() {
        NotificationCenter.default.post(name: .reloadOverview, object: nil)
    }
    
    func checkHealthKit(isShow: Bool) {
        if !Settings.didFinishCommunitySignup && !Settings.skippedCommunitySignup {
            if let vc = UIApplication.shared.keyWindow?.topViewController {
                if !vc.isKind(of: CommunityViewController.self) && isShow {
                    showInitialController()
                }
            }
        } else {
            for (index, type) in ZBFHealthKit.hkShareTypes.enumerated()  {
                switch ZBFHealthKit.healthStore.authorizationStatus(for: type) {
                case .notDetermined:
                    if isShow {
                        showHealthKitController(isFailed: false)
                    }
                    return
                case .sharingDenied:
                    if isShow {
                        showHealthKitController(isFailed: true)
                    }
                    return
                case .sharingAuthorized:
                    if index == ZBFHealthKit.hkShareTypes.count - 1 {
                        if let vc = UIApplication.shared.keyWindow?.topViewController {
                            if vc.isKind(of: HealthKitViewController.self) || vc.isKind(of: NavigationControllerWelcome.self) {
                                
                                if vc.isKind(of: NavigationControllerWelcome.self),
                                    let nc = vc as? NavigationControllerWelcome,
                                    let top = nc.topViewController,
                                    !top.isKind(of: WatchSyncError.self) {
                                    
                                    vc.dismiss(animated: true)
                                } else {
                                    
                                    vc.dismiss(animated: true)
                                }
                                
                            }
                        }
                        updateOverview()
                    }
                }
            }
        }
    }
    
    
    func startingSession() {
//        Settings.checkSubscriptionAvailability { success, trial in
//
//            if trial {
//                let startingSessions = StartingSessionViewController()
//                startingSessions.modalPresentationStyle = .overFullScreen
//                startingSessions.modalTransitionStyle = .crossDissolve
//                self.present(startingSessions, animated: true)
//                return
//            }
//
//            if success {
//                let startingSessions = StartingSessionViewController()
//                startingSessions.modalPresentationStyle = .overFullScreen
//                startingSessions.modalTransitionStyle = .crossDissolve
//                self.present(startingSessions, animated: true)
//            } else {
//                let vc = SubscriptionViewController.loadFromStoryboard()
//                self.present(vc, animated: true)
//            }
//        }
        
    }
        
}



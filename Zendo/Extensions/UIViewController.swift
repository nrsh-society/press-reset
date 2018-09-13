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
    
    func showWelcomeController() {
        if let vc = UIApplication.shared.keyWindow?.topViewController {
            if !vc.isKind(of: WelcomeController.self) {
                let controller = WelcomeController.loadFromStoryboard()
                present(controller, animated: true)
            }
        }
    }
    
    func showHealthKitController(isFailed: Bool) {
        let controller = HealthKitViewController.loadFromStoryboard()
        controller.isFailed = isFailed
        present(controller, animated: true)
    }
    
    func updateOverview() {
        NotificationCenter.default.post(name: .reloadOverview, object: nil)
    }
    
    func checkHealthKit(isShow: Bool) {
        if !Settings.isRunOnce {
            if let vc = UIApplication.shared.keyWindow?.topViewController {
                if !vc.isKind(of: CommunityViewController.self) {
                    showWelcomeController()
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
                            if vc.isKind(of: HealthKitViewController.self) || vc.isKind(of: WelcomeController.self) {
                                vc.dismiss(animated: true)
                            }
                        }
                        updateOverview()
                    }
                }
            }
        }
    }
    
}

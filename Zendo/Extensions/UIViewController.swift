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
    
    func showWelcomeController() {
        let controller = WelcomeController.loadFromStoryboard()
        present(controller, animated: true)
    }
    
    func showHealthKitController(isFailed: Bool) {
        let controller = HealthKitViewController.loadFromStoryboard()
        controller.isFailed = isFailed
        present(controller, animated: true)
    }
    
    func checkHealthKit() {
        if !Settings.isRunOnce {
            showWelcomeController()
        } else {
            for type in ZBFHealthKit.hkShareTypes  {
                switch ZBFHealthKit.healthStore.authorizationStatus(for: type) {
                case .notDetermined: showHealthKitController(isFailed: false)
                case .sharingDenied: showHealthKitController(isFailed: true)
                case .sharingAuthorized: break
                }
                break
            }
        }
    }
    
}

//
//  StartingSessionVC.swift
//  Zendo
//
//  Created by Egor Privalov on 31/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import HealthKit
import Mixpanel
import WatchConnectivity

class StartingSessionViewController: UIViewController {
    
    let startingSessions = StartingSessions()
    let healthStore = ZBFHealthKit.healthStore
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        startingSessions.setLayoutConstraint(view, secondView: view)
        startingSessions.startAction = {
            
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .mindAndBody
            configuration.locationType = .unknown
            
            self.healthStore.startWatchApp(with: configuration) { success, error in
                
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
                
                guard success else {
                    let vc = WatchSyncError.loadFromStoryboard()
                    
                    if error?.code == 7 {
                        vc.errorConfiguration = .needWear
                    } else {
                        if WCSession.isSupported() {
                            let session = WCSession.default
                            
                            if !session.isPaired {
                                vc.errorConfiguration = .noAppleWatch
                            } else if !WCSession.default.isWatchAppInstalled {
                                vc.errorConfiguration = .noInstallZendo
                            } else {
                                let alert = UIAlertController(title: "Error", message: (error?.localizedDescription)!, preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
                                    self.checkHealthKit(isShow: true)
                                })
                                DispatchQueue.main.async {
                                    self.present(alert, animated: true)
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500) ) {
                        UIApplication.topViewController()?.present(vc, animated: true)
                    }
                    
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1) ) {
                    Mixpanel.mainInstance().track(event: "new_session")
                }
            }
        }
        
        startingSessions.closeAction = {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startingSessions.showView()
    }
    
}

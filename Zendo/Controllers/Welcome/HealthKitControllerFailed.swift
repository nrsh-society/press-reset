//
//  HealthKitControllerFailed.swift
//  Zendo
//
//  Created by Boris Sedov on 05.06.2020.
//  Copyright © 2020 zenbf. All rights reserved.
//
    

import UIKit
import Mixpanel

class HealthKitControllerFailed: UIViewController {
    
    @IBOutlet weak var zenButton: ZenButton!
    
}

// MARK: - LifeCycle

extension HealthKitControllerFailed {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        zenButton.action = { [weak self] in
            if let url = URL(string: "x-apple-health://"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            self?.dismiss(animated: true)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
           super.viewDidAppear(animated)
           
           Mixpanel.mainInstance().time(event: "healthkit")

       }
       
       override func viewWillDisappear(_ animated: Bool) {
           super.viewWillDisappear(animated)
           
           Mixpanel.mainInstance().track(event: "healthkit")
       }
    
}

// MARK: - Static

extension HealthKitControllerFailed {
    
    class func loadFromStoryboard() -> HealthKitControllerFailed {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HealthKitControllerFailed") as! HealthKitControllerFailed
    }
    
}

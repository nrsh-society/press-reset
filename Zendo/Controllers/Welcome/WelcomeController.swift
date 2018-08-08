//
//  WebController.swift
//  Zendo
//
//  Created by Douglas Purdy on 4/4/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Foundation
import HealthKit

class WelcomeController: UIViewController {
    
    @IBOutlet weak var topStackView: NSLayoutConstraint!
    @IBOutlet var labels: [UILabel]!
    @IBOutlet weak var zenButton: ZenButton!
    var isDismiss = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        zenButton.action = {
            self.isDismiss = true
            Settings.isRunOnce = true
            let vc = HealthKitViewController.loadFromStoryboard()
            self.present(vc, animated: true)
        }
        
        if UIDevice.small {
            topStackView.constant = 20
            for label in labels {
                label.font = UIFont.zendo(font: .antennaRegular, size: label.font.pointSize - 2)
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isDismiss {
            self.dismiss(animated: true)
        }
    }
    
    static func loadFromStoryboard() -> WelcomeController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeController") as! WelcomeController
    }
    
}

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        zenButton.action = {
            
            ZBFHealthKit.requestHealthAuth(handler: { success, error in
                DispatchQueue.main.async() {
                    if success {
                        Settings.isRunOnce = true
                        self.dismiss(animated: true)
                    } else {
                        let image = UIImage(named: "healthkit")
                        let frame = self.view.frame
                        
                        let hkView = UIImageView(frame: frame)
                        hkView.image = image;
                        hkView.contentMode = .scaleAspectFit
                        
                        self.view.addSubview(hkView)
                        self.view.bringSubview(toFront: hkView)
                    }
                }
            })
        }
        
        if UIDevice.small {
            topStackView.constant = 20
            for label in labels {
                label.font = UIFont.zendo(font: .antennaRegular, size: label.font.pointSize - 2)
            }
        }
        
    }
    
    static func loadFromStoryboard() -> WelcomeController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeController") as! WelcomeController
    }
    
}

//
//  HealthKitViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 08/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

class HealthKitViewController: UIViewController {
    
    @IBOutlet var labels: [UILabel]!
    @IBOutlet weak var heightImage: NSLayoutConstraint!
    @IBOutlet weak var zenButton: ZenButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.small {
            for label in labels {
                label.font = UIFont.zendo(font: .antennaRegular, size: label.font.pointSize - 2)
            }
        }
        
        if UIDevice.iPhoneX {
            heightImage.isActive = false
        }
        
        zenButton.action = {
            ZBFHealthKit.requestHealthAuth(handler: { success, error in
                DispatchQueue.main.async() {
                    print(success)
                    if success {
                        self.dismiss(animated: true)
                    }
                }
            })
        }
    }
    
    static func loadFromStoryboard() -> HealthKitViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HealthKitViewController") as! HealthKitViewController
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

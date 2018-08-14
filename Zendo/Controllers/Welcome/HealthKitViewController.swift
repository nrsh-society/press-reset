//
//  HealthKitViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 08/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Mixpanel

class HealthKitViewController: UIViewController {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet var labels: [UILabel]!
    @IBOutlet weak var heightImage: NSLayoutConstraint!
    @IBOutlet weak var zenButton: ZenButton!
    
    var isFailed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Mixpanel.mainInstance().time(event: isFailed ? "healthKit_failed-connect_enter" : "healthKit-connect_enter")
        
        if UIDevice.small {
            for label in labels {
                label.font = UIFont.zendo(font: .antennaRegular, size: label.font.pointSize - 2)
            }
        }
        
        if UIDevice.iPhoneX {
            heightImage.isActive = false
        }
        
        if isFailed {
            setConnectFailed()
        }
        
        zenButton.action = {
            if self.isFailed {
                UIApplication.shared.open(URL(string: "x-apple-health://")!)
                Mixpanel.mainInstance().time(event: "healthKit_failed-connect_exit" )
                self.dismiss(animated: true)
            } else {
                ZBFHealthKit.requestHealthAuth(handler: { success, error in
                    DispatchQueue.main.async() {
                        if success {
                            
                            for type in ZBFHealthKit.hkShareTypes  {
                                switch ZBFHealthKit.healthStore.authorizationStatus(for: type) {
                                case .notDetermined: break
                                case .sharingDenied:
                                    self.isFailed = true
                                    self.setConnectFailed()
                                case .sharingAuthorized:
                                    Mixpanel.mainInstance().time(event: "healthKit-connect_exit" )
                                    self.dismiss(animated: true)
                                }
                                break
                            }
                        }
                    }
                })
            }
        }
    }
    
    func setConnectFailed() {
        for label in labels {
            switch label.tag {
            case 0: label.text = "health app"
            case 1: label.text = "sync failed"
            case 2:
                let text =
                """
                    In order to provide you with the most opitmial experience we need to be able to connect to your health app.

                    1. Go to Health app.
                    2. Tap on the Source Tab.
                    3. Locate and Tap on Zendō
                    4. Tap on Turn All Categories On.
                    """
                let attributedString = NSMutableAttributedString(string: text)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineHeightMultiple = 1.43
                
                attributedString.addAttribute(.paragraphStyle, value:paragraphStyle, range: NSMakeRange(0, attributedString.length))
                
                label.attributedText = attributedString
            default: break
            }
        }
        image.image = UIImage(named: "connectFailed")
        zenButton.title.text = "Go to Health App"
    }
    
    static func loadFromStoryboard() -> HealthKitViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HealthKitViewController") as! HealthKitViewController
    }
    
}

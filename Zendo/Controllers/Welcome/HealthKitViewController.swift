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
        
        if UIDevice.small || checkZoomed() {
            for label in labels {
                label.font = UIFont.zendo(font: .antennaRegular, size: label.font.pointSize - 3)
            }
        }
        
        if UIDevice.X {
            heightImage.isActive = false
        }
        
        if isFailed {
            setConnectFailed()
        }
        
        zenButton.action = {
            if self.isFailed {
                UIApplication.shared.open(URL(string: "x-apple-health://")!)
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
                                    self.updateOverview()
                                    self.dismiss(animated: true)
                                /*
                                    let vc = PairDevicesController.loadFromStoryboard()
                                    self.navigationController?.pushViewController(vc, animated: true)
                                    */
                                }
                                break
                            }
                            
                        }
                    }
                })
            }
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
    
    func setConnectFailed() {
        
        Mixpanel.mainInstance().track(event: "healthkit_failed" )
        
        for label in labels {
            switch label.tag {
            case 0: label.text = "health app"
            case 1: label.text = "sync failed"
            case 2: label.text =
            """
            Zendō requires access to Health App.
            
            1. Go to Health app.
            2. Tap on the Source Tab.
            3. Locate and Tap on Zendō
            4. Tap on Turn All Categories On.
            """
            
            label.attributedText = setAttributedString(label.text ?? "")
            default: break
            }
        }
        image.image = UIImage(named: "connectFailed")
        zenButton.title.text = "Go to Health App"
    }
    
    func setAttributedString(_ text: String) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.43
        
        attributedString.addAttribute(.paragraphStyle, value:paragraphStyle, range: NSMakeRange(0, attributedString.length))
        
        return attributedString
    }
    
    class func loadFromStoryboard() -> HealthKitViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HealthKitViewController") as! HealthKitViewController
    }
    
}

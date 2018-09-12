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
import Mixpanel

class WelcomeController: UIViewController {
    
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var topStackView: NSLayoutConstraint!
    @IBOutlet weak var zenButton: ZenButton!
    @IBOutlet var labels: [UILabel]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        zenButton.action = {
            self.dismiss(animated: true, completion: {
                if let vc = UIApplication.shared.keyWindow?.topViewController {
                    let community = CommunityViewController.loadFromStoryboard()
                    vc.present(community, animated: true)
                }
            })
        }
        
        for label in labels {
            label.font = UIFont.zendo(font: .antennaRegular, size: label.font.pointSize - (UIDevice.small ? 2 : 0))
            if label.tag == 2 {
                let attributedString = NSMutableAttributedString(string: label.text ?? "")
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineHeightMultiple = 1.43
                
                attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
                
                label.attributedText = attributedString
            }
        }
        
        if UIDevice.small {
            imageHeight.constant = 280
            topStackView.constant = 20
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.mainInstance().time(event: "welcome")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "welcome")
    }
    
    static func loadFromStoryboard() -> WelcomeController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeController") as! WelcomeController
    }
    
}

//
//  PairStatusController.swift
//  Zendo
//
//  Created by Boris Sedov on 09.01.2020.
//  Copyright © 2020 zenbf. All rights reserved.
//

import UIKit

enum PairStatus {
    case paired, noDetected
    
    var firstText: String {
        switch self {
        case .paired: return "device"
        case .noDetected: return "no device"
        }
    }
    
    var secondText: String {
        switch self {
        case .paired: return "paired"
        case .noDetected: return "detected"
        }
    }
    
    var thirdText: String {
        switch self {
        case .paired: return
            "You successfully connected to your Apple Watch or Zensor."
        case .noDetected: return
            "In order to record a meditation session, Zendô requires a connnected heart rate device. Try connecting an Appie Watch or Zensor."
        }
    }
    
    var buttonText: String {
        switch self {
        case .paired: return "Get Started"
        case .noDetected: return "Try Again"
        }
    }
    
    var image: UIImage? {
        switch self {
        case .paired: return UIImage(named: "watchConnectSuccess")
        case .noDetected: return UIImage(named: "watchConnectNonePaired")
        }
    }
    
}

class PairStatusController: UIViewController {
    
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var button: ZenButton!
    
    var status = PairStatus.noDetected

    override func viewDidLoad() {
        super.viewDidLoad()
        
        button.titleButton = status.buttonText
        imageView.image = status.image
        firstLabel.text = status.firstText
        secondLabel.text = status.secondText
        thirdLabel.text = status.thirdText
        
        button.action = {
            self.dismiss(animated: true)
        }
        
    }
    
}

// MARK: - Static

extension PairStatusController {
    
    static func loadFromStoryboard() -> PairStatusController {
        return UIStoryboard(name: "PairDevices", bundle: nil).instantiateViewController(withIdentifier: "PairStatusController") as! PairStatusController
    }
    
}

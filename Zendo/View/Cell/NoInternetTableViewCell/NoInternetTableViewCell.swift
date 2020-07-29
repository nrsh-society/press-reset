//
//  NoInternetTableViewCell.swift
//  Zendo
//
//  Created by Anton Pavlov on 29/11/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Lottie

class NoInternetTableViewCell: UITableViewCell {
    
    @IBOutlet weak var animationView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let animFrame = CGRect(x: -(animationView.bounds.width / 2.0), y: -(animationView.bounds.height / 2.0), width: animationView.bounds.width * 2, height: animationView.bounds.height * 2)        
        
        let wifiAnimation = AnimationView(name: "animationNoInternet")
        wifiAnimation.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        wifiAnimation.contentMode = .scaleAspectFill
        wifiAnimation.frame = animFrame
        wifiAnimation.animationSpeed = 1
        wifiAnimation.loopMode = .loop
        
        animationView.addSubview(wifiAnimation)
        
        wifiAnimation.play()
    }
    
}

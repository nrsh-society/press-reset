//
//  StartingSessions.swift
//  Zendo
//
//  Created by Egor Privalov on 31/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Lottie
import HealthKit
import Mixpanel

class StartingSessions: UIView {
    
    @IBOutlet weak var startingSessionLabel: UILabel!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var cancelButton: ZenButton!
    @IBOutlet weak var countLabel: UILabel!
    
    let circleAnimation = AnimationView(name: "animationStartingSession")
    let healthStore = ZBFHealthKit.healthStore
    
    let newSessionHeight = UIScreen.main.bounds.height / 2
    var closeAction: (()->())?
    var startAction: (()->())?
    var timer: Timer?
    var seconds = 5
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        clipsToBounds = true
        layer.roundCorners(corners: [.topLeft, .topRight], radius: 10)
        
        animationView.insertSubview(circleAnimation, at: 0)
        
        circleAnimation.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        circleAnimation.contentMode = .scaleAspectFill
        circleAnimation.frame = animationView.bounds
        circleAnimation.animationSpeed = 0.6
        
        cancelButton.bottomView.anchor(top: nil, bottom: nil, leading: cancelButton.leadingAnchor, trailing: cancelButton.trailingAnchor)
        
        cancelButton.title.textAlignment = .center
        cancelButton.titleButton = "cancel"
        cancelButton.action = {
            self.hideView()
            self.closeAction?()
        }
    }
    
    func setLayoutConstraint(_ mainView: UIView, secondView: UIView) {
        mainView.addSubview(self)
        
        anchor(top: secondView.bottomAnchor, bottom: nil, leading: secondView.leadingAnchor, trailing: secondView.trailingAnchor)
        height(newSessionHeight)
    }
    
    func showView() {
    
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(count), userInfo: nil, repeats: true)
        
        circleAnimation.play { finished in
//            self.hideView()
        }
        
        UIView.animate(withDuration: 0.5) {
            self.transform = CGAffineTransform(translationX: 0, y: -self.newSessionHeight)
        }
    }
    
    func hideView() {
        timer?.invalidate()
        UIView.animate(withDuration: 0.3, animations: {
            self.transform = CGAffineTransform.identity
        }, completion: { (completion) in
            self.circleAnimation.stop()
        })
    }
    
    @objc func count() {
        seconds -= 1
        countLabel.text = String(seconds)
        
        if seconds == 0 {
            countLabel.text = ""
            startAction?()
            hideView()
        }
    }
}

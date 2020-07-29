//
//  StartSessionView.swift
//  Zendo
//
//  Created by Boris Sedov on 10.01.2020.
//  Copyright © 2020 zenbf. All rights reserved.
//

import UIKit
import Lottie
import HealthKit
import Mixpanel
import WatchConnectivity

class  StartSessionView: UIView {
    
    @IBOutlet weak var lenghtStack: UIStackView!
    @IBOutlet weak var chooseStack: UIStackView!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(PairDevicesTableCell.nib, forCellReuseIdentifier: PairDevicesTableCell.reuseIdentifierCell)
            tableView.tableFooterView = UIView()
        }
    }
    @IBOutlet weak var startingSessionLabel: UILabel!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var cancelButton: ZenButton!
    @IBOutlet weak var countLabel: UILabel!
    
    let circleAnimation = AnimationView(name: "animationStartingSession")
    let healthStore = ZBFHealthKit.healthStore
    
    let newSessionHeight = UIScreen.main.bounds.height / 2
    var closeAction: (()->())?
    var startAction: ((_ type: TypeDeviceLE) -> ())?
    var timer: Timer?
    var seconds = 5
    var devices = [DeviceLE]()
    
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
        cancelButton.titleButton = "Cancel"
        cancelButton.action = {
            
            if self.cancelButton.titleButton == "Cancel" {
                self.hideView()
                self.closeAction?()
            } else if self.cancelButton.titleButton == "Connect" {
                                
                for device in self.devices {
                    if device.isSelect {
                        if device.type == .aw {
                            self.startingSessionLabel.text = "starting session on your Apple Watch"
                        } else {
                            self.startingSessionLabel.text = "starting session on your MoveSense"
                        }
                        self.startCountdown()
                    }
                }
                
                
            }
            
        }
    }
    
    func setLayoutConstraint(_ mainView: UIView, secondView: UIView) {
        mainView.addSubview(self)
        
        anchor(top: secondView.bottomAnchor, bottom: nil, leading: secondView.leadingAnchor, trailing: secondView.trailingAnchor)
        height(newSessionHeight)
    }
    
    func showView(devices: [DeviceLE]) {
        
        animationView.isHidden = true
        tableView.isHidden = true
        startingSessionLabel.isHidden = true
        lenghtStack.isHidden = true
        chooseStack.isHidden = true
                
        UIView.animate(withDuration: 0.5) {
            self.transform = CGAffineTransform(translationX: 0, y: -self.newSessionHeight)
        }
        
        if devices.count >= 2 {
            
            animationView.isHidden = true
            tableView.isHidden = false
            startingSessionLabel.isHidden = true
            cancelButton.titleButton = "Connect"
            lenghtStack.isHidden = false
            chooseStack.isHidden = false
            
            self.devices = devices
            self.tableView.reloadData()
            
        } else if devices.count == 1 {
                        
            if devices[0].type == .aw {
                startingSessionLabel.text = "starting session on your Apple Watch"
            } else {
                startingSessionLabel.text = "starting session on your MoveSense"
            }
            
            startCountdown()
            
        }
        
    }
    
    func startCountdown() {
        
        seconds = 5
        countLabel.text = String(seconds)
        
        lenghtStack.isHidden = true
        chooseStack.isHidden = true
        startingSessionLabel.isHidden = false
        animationView.isHidden = false
        tableView.isHidden = true
        cancelButton.titleButton = "Cancel"
                
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(count), userInfo: nil, repeats: true)
        
        circleAnimation.play()
    }
    
    func hideView() {
        timer?.invalidate()
        timer = nil
        UIView.animate(withDuration: 0.3, animations: {
            self.transform = CGAffineTransform.identity
        }, completion: { completion in
            self.circleAnimation.stop()
        })
    }
    
    @objc func count() {
        seconds -= 1
        countLabel.text = String(seconds)
        
        if seconds == 0 {
            countLabel.text = ""
            for d in devices {
                if d.isSelect {
                    startAction?(d.type)
                }
            }
            hideView()
        }
    }
}


extension StartSessionView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        for device in devices {
            device.isSelect = false
        }
        
        devices[indexPath.row].isSelect = true
        
        tableView.reloadData()
        
    }
    
}

extension StartSessionView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PairDevicesTableCell.reuseIdentifierCell, for: indexPath) as! PairDevicesTableCell
        
        cell.nameLabel.text = devices[indexPath.row].name
        cell.imageCheck.isHidden = !devices[indexPath.row].isSelect
        
        return cell
    }
    
    
}

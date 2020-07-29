//
//  LabController.swift
//  Zendo
//
//  Created by Douglas Purdy on 5/8/20.
//  Copyright © 2020 zenbf. All rights reserved.
//

import UIKit
import Hero
import SpriteKit
import Firebase
import FirebaseDatabase
import HealthKit
import AVKit
import Mixpanel
import Cache
import SwiftyJSON
import WebKit
import SceneKit

class LabController: UIViewController
{
    
    static func loadFromStoryboard() -> LabController
    {
        let controller = UIStoryboard(name: "LabController", bundle: nil).instantiateViewController(withIdentifier: "LabController") as! LabController
        
        return controller
    }
    
    var appleWatch : Zensor?
    var story: Story!
    var idHero = ""
    var panGR: UIPanGestureRecognizer!
    var chartHR = [String: Int]()
    
    @IBOutlet weak var sceneView: SCNView!
    {
        
        didSet {
            sceneView.hero.id = idHero
        }
    }
    
    @IBOutlet weak var progressView: ProgressView! {
            didSet {

                progressView.isHidden = true
                progressView.alpha = 1.0
                self.progressView.hrv.text = "--"
                self.progressView.time.text = "--"
                
            }
        }
    
    
    @IBOutlet weak var connectButton: UIButton!
    
    @IBOutlet weak var arenaView: ArenaView! {
        didSet {

            arenaView.isHidden = true
            arenaView.alpha = 1.0
            self.arenaView.hrv.text = "--"
            self.arenaView.time.text = "--"
            
        }
    }
    
   
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        Mixpanel.mainInstance().time(event: "phone_lab")
        
        setupWatchNotifications()
        
        do {
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        
        modalPresentationCapturesStatusBarAppearance = true
        
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
        
        sceneView.addGestureRecognizer(panGR)
        
        setupConnectButton()
        
        self.startSession()

    }
    
   
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "phone_lab", properties: ["name": story.title])
        
        NotificationCenter.default.removeObserver(self)
                
        UIApplication.shared.isIdleTimerDisabled = false
        
    }
    
    func setupConnectButton()
    {
        self.connectButton.addTarget(self, action: #selector(connectAppleWatch), for: .primaryActionTriggered)
        
        self.connectButton.layer.borderColor = UIColor.white.cgColor
        self.connectButton.layer.borderWidth = 1.0
        self.connectButton.layer.cornerRadius = 10.0
        self.connectButton.backgroundColor = UIColor(red:0.06, green:0.15, blue:0.13, alpha:0.3)
        self.connectButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.connectButton.layer.shadowColor = UIColor(red:0, green:0, blue:0, alpha:0.5).cgColor
        self.connectButton.layer.shadowOpacity = 1
        self.connectButton.layer.shadowRadius = 20
    }
    
    func setupWatchNotifications()
    {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sample),
                                               name: .sample,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.progress),
                                               name: .progress,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(startSession),
                                               name: .startSession,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(endSession),
                                               name: .endSession,
                                               object: nil)
 
    }
    
    

    
    @objc func connectAppleWatch()
    {
        let startingSessions = StartingSessionViewController()
        
        startingSessions.modalPresentationStyle = .overFullScreen
        
        startingSessions.modalTransitionStyle = .crossDissolve
        
        self.present(startingSessions, animated: true)
        
    }
    
    @objc func startSession()
    {
        if(Settings.isSensorConnected)
        {
            Mixpanel.mainInstance().time(event: "phone_lab_watch_connected")
            
            DispatchQueue.main.async
            {
                UIView.animate(withDuration: 0.5)
                {
                    self.arenaView.isHidden = false
                    self.connectButton.isHidden = true
                }

            }
        
        }
    }

    @objc func endSession()
    {
        Mixpanel.mainInstance().track(event: "phone_lab_watch_connected",
                                          properties: ["name": self.story.title])
        DispatchQueue.main.async
        {
            UIView.animate(withDuration: 0.5)
            {
                    
                    self.arenaView.isHidden = true
                    self.connectButton.isHidden = false
                    
                    self.arenaView.hrv.text = "--"
                    self.arenaView.time.text = "--"
                    self.arenaView.setChart([])
                }
                
            }
            
        }
    
    @objc func progress(notification: NSNotification)
    {
        if let progress = notification.object as? String
        {
            let lastProgress = progress.description.lowercased().contains("true")
            
            if let watch  = self.appleWatch
            {
                watch.update(progress: progress.description.lowercased())
            }
        }
    }
    
    @objc func sample(notification: NSNotification)
    {
        if let sample = notification.object as? [String : Any]
        {
            let raw_hrv = sample["sdnn"] as! String
            let double_hrv = Double(raw_hrv)!.rounded()
            let text_hrv = Int(double_hrv.rounded()).description
            
            let raw_hr = sample["heart"] as! String
            let double_hr = (Double(raw_hr)! * 60).rounded()
            let int_hr = Int(double_hr)
            let text_hr = int_hr.description
            
            
            DispatchQueue.main.async
            {
                self.arenaView.hrv.text = text_hrv
                
                self.arenaView.time.text = text_hr
                
                self.chartHR[String(Date().timeIntervalSince1970)] = int_hr
            
                let chartHR = self.chartHR.sorted(by: <)

                self.arenaView.setChart(chartHR)
    
            }
            
            if let watch  = self.appleWatch
            {
                watch.update(hr: Float(double_hr) )
            }
            else
            {
                self.appleWatch = Zensor(id: UUID() , name: Settings.email!, hr: Float(double_hr) , batt: 100)
            }
        }
        
    }
        
    @objc func pan()
    {
        let translation = panGR.translation(in: nil)
        let progress = translation.y / view.bounds.height
        switch panGR.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
          //  Hero.shared.apply(modifiers: [.position(currentPos)], to: twitchView)
        default:
            
             Hero.shared.finish()
            
        }

    }
}




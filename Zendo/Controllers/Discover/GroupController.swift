//
//  ViewController.swift
//  zendō arena
//
//  Created by Douglas Purdy on 2/5/19.
//  Copyright © 2019 Zendo Tools. All rights reserved.
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

class GroupController: UIViewController
{
    @IBOutlet weak var spriteView: SKView!
    {
        didSet {
            spriteView.hero.id = idHero
        }
    }
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var avatarView: UIView!
    @IBOutlet weak var playersLabel: UILabel!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var playersTitle: UILabel!
    @IBOutlet weak var minutesTitle: UILabel!
    
    @IBOutlet weak var arenaView: ArenaView! {
        didSet {

            arenaView.isHidden = true
            arenaView.alpha = 1.0
            arenaView.hrv.text = "--"
            arenaView.time.text = "--"
        }
    }

    var story: Story!
    var idHero = ""
    var panGR: UIPanGestureRecognizer!
    var airplay: AirplayController?
    var chartHR = [String: Int]()
    var scene : SKScene?
    var players = [String : Int]()
    
    let diskConfig = DiskConfig(name: "DiskCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    
    lazy var storage: Cache.Storage? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()
    
    static func loadFromStoryboard() -> GroupController
    {
       let controller = UIStoryboard(name: "GroupController", bundle: nil).instantiateViewController(withIdentifier: "GroupController") as! GroupController

        return controller
        
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        try? storage?.removeAll()
    }
    
    func airplay(_ url: URL)
    {
        if let airplay = self.airplay
        {
            airplay.dismiss()
            airplay.dismiss(animated: true, completion: nil)
        }
        
        self.airplay = AirplayController.loadFromStoryboard(url)
    }
    
    func setBackground() {
        if let story = story, let thumbnailUrl = story.thumbnailUrl, let url = URL(string: thumbnailUrl) {
            UIImage.setImage(from: url) { image in
                DispatchQueue.main.async {
                    self.spriteView.addBackground(image: image, isLayer: false, isReplase: false)
                }
            }
        }
    }
    
    func removeBackground()
    {
        if let viewWithTag = self.view.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
        }
    }
    
    func startBackgroundContent(story : Story, completion: @escaping (AVPlayerItem) -> Void)
    {
        var playerItem: AVPlayerItem?
        
        let streamString = story.content[0].stream
        let downloadString = story.content[0].download
        let airplayString = story.content[0].airplay
        
        var downloadUrl : URL?
        var streamUrl : URL?
        
        if let urlString = downloadString, let url = URL(string: urlString)
        {
            downloadUrl = url
        }
        
        if let urlString = streamString, let url = URL(string: urlString)
        {
            streamUrl = url
        }
        
        if let urlString = airplayString, let url = URL(string: urlString)
        {
            self.airplay(url)
        }
        
        storage?.async.entry(forKey: downloadUrl?.absoluteString ?? "", completion:
        {
            result in
            
            switch result
            {
                case .value(let entry):
                
                    if var path = entry.filePath
                    {
                        if path.first == "/"
                        {
                            path.removeFirst()
                        }
                    
                        let url = URL(fileURLWithPath: path)
                    
                        playerItem = AVPlayerItem(url: url)
                    }
            
                default:
                    
                    if let url = streamUrl
                    {
                        playerItem = AVPlayerItem(url: url)
                    }
                    else
                    {
                        playerItem = AVPlayerItem(url: downloadUrl!)
                    }
            }
            
            completion(playerItem!)
            
        })
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "phone_train", properties: ["name": story.title])
        
        NotificationCenter.default.removeObserver(self)
        
        spriteView.scene?.removeAllChildren()
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        self.spriteView.presentScene(nil)
        self.scene = nil
        
        self.airplay?.dismiss()
        self.airplay = nil
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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setBackground()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        Mixpanel.mainInstance().time(event: "phone_train")
        
        setupWatchNotifications()
        
        do {
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        
        modalPresentationCapturesStatusBarAppearance = true
        
        self.spriteView.presentScene(self.setupScene())
        
        self.startSession()
        
    }
    
    @objc func connectAppleWatch()
    {
        if(!Settings.isWatchConnected) {
            
            let startingSessions = StartingSessionViewController()
            
            startingSessions.modalPresentationStyle = .overFullScreen
            
            startingSessions.modalTransitionStyle = .crossDissolve
            
            self.present(startingSessions, animated: true)
            
        }
    }
    
    @objc func startSession()
    {

        if(Settings.isWatchConnected)
        {
            Mixpanel.mainInstance().time(event: "phone_train_watch_connected")
            
            Cloud.registerPlayersChangedHandler
            {
                (players, error) in
                
                self.players = players
                
                DispatchQueue.main.async
                {
                    UIView.animate(withDuration: 0.5)
                    {
                        self.playersLabel.text = self.players.count.description
                        self.minutesLabel.text = self.players.reduce(0,
                        {
                            return $0 + $1.value
                        }).description

                    }
                }
            }
            
            Cloud.updatePlayer(email: Settings.email!, mins: 0)
            
            DispatchQueue.main.async
            {
                UIView.animate(withDuration: 0.5)
                {
                    self.arenaView.isHidden = false
                    self.connectButton.isHidden = true
                    self.avatarView.isHidden = true
                    self.playersLabel.isHidden = false
                    self.minutesLabel.isHidden = false
                    self.playersTitle.isHidden = false
                    self.minutesTitle.isHidden = false
                }
                
            }
            
        }
    }
    
    @objc func endSession()
    {
        Mixpanel.mainInstance().track(event: "phone_train_watch_connected",
                                          properties: ["name": self.story.title])
        
        Cloud.removePlayer(email: Settings.email!)
        
        DispatchQueue.main.async
        {
            
            UIView.animate(withDuration: 0.5)
            {
                    self.arenaView.isHidden = true
                    self.connectButton.isHidden = false
                
                    self.arenaView.hrv.text = "--"
                    self.arenaView.time.text = "--"
                    self.arenaView.setChart([])
                    self.playersLabel.isHidden = true
                    self.minutesLabel.isHidden = true
                    self.playersTitle.isHidden = true
                    self.minutesTitle.isHidden = true
                }
            }
        }
    
    @objc func progress(notification: NSNotification)
    {
        if let progress = notification.object as? [String]
        {
            Cloud.updatePlayer(email: Settings.email!, mins: progress.count)
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
        }
        
    }
    
    
    func setupScene() -> SKScene
    {
        spriteView.frame = UIScreen.main.bounds
        spriteView.contentMode = .scaleAspectFill
        
        let scene = SKScene(size: (spriteView.frame.size))
        
        scene.scaleMode = .aspectFill
        
        spriteView.allowsTransparency = true
        
        self.startBackgroundContent(story: story, completion:
        {
            item in
            
            DispatchQueue.main.async
            {
                let videoPlayer = AVPlayer(playerItem: item)
                
                let video = SKVideoNode(avPlayer: videoPlayer)
                    
                video.zPosition = 1.0
                video.size = scene.frame.size
                video.position = scene.position
                video.anchorPoint = scene.anchorPoint
                video.play()
                scene.addChild(video)
                
                self.removeBackground()
                    
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                           object: videoPlayer.currentItem, queue: nil)
                    {
                       notification in
                        
                        DispatchQueue.main.async
                        {
                            videoPlayer.seek(to: kCMTimeZero)
                            videoPlayer.play()
                        }
                        
                    }
                }
            
        })
    
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
        spriteView.addGestureRecognizer(panGR)
        
        setupConnectButton()
        
        return scene
        
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
            Hero.shared.apply(modifiers: [.position(currentPos)], to: spriteView)
        default:
            
             Hero.shared.finish()
            
        }

    }
}

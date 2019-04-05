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


class TrainController: UIViewController
{
    @IBOutlet weak var spriteView: SKView!
    {
        didSet {
            spriteView.hero.id = idHero
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
    
    var player = SKSpriteNode(imageNamed: "player1")
    var ring: Int = 0
    var story: Story!
    var video: SKVideoNode?
    var idHero = ""
    var timer: Timer?
    var videoPlayer = AVPlayer()
    var panGR: UIPanGestureRecognizer!
    var showLevels : Bool = false
    var airplay: AirplayController?
    var isConnected: Bool = false
    var connectedDate : Date?
    var chartHR = [String: Int]()
    var rings = [SKShapeNode]()
    
    let diskConfig = DiskConfig(name: "DiskCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    
    lazy var storage: Cache.Storage? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()
    
    static func loadFromStoryboard(_ showLevels: Bool) -> TrainController
    {
       let controller = UIStoryboard(name: "TrainController", bundle: nil).instantiateViewController(withIdentifier: "TrainController") as! TrainController
        
        controller.showLevels = showLevels
        
        return controller
        
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
        
        video?.pause()
        spriteView.scene?.removeAllChildren()
        
        UIApplication.shared.isIdleTimerDisabled = false
        
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
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        Mixpanel.mainInstance().time(event: "phone_train")
    
        setupWatchNotifications()
        
        modalPresentationCapturesStatusBarAppearance = true
        
        self.spriteView.presentScene(self.setupScene())
        
        self.startSession()
        
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
        Mixpanel.mainInstance().time(event: "phone_train_watch_connected")
        
        let scene = self.spriteView.scene!
        
        if(Settings.isWatchConnected)
        {
            self.connectedDate = Date()
            
            DispatchQueue.main.async
            {
                if(self.showLevels)
                {
                    
                    self.arenaView.isHidden = false
                    self.connectButton.isHidden = true
                    
                    self.rings.forEach( {$0.isHidden = false })
                    
                    if let shell = self.spriteView.scene!.childNode(withName: "//0")! as? SKShapeNode
                    {
                        shell.addChild(self.player)
                        
                        self.player.zPosition = 3.0
                        
                        let action = SKAction.repeatForever(SKAction.follow(shell.path!, asOffset: false, orientToPath: true, speed: 15.0))
                        
                        self.player.run(action)
                    }
                    
                    self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
                }
            }
        }
    }
    
    @objc func endSession()
    {
        Mixpanel.mainInstance().track(event: "phone_train_watch_connected",
                                          properties: ["name": self.story.title])
            DispatchQueue.main.async
            {
                self.arenaView.isHidden = true
                self.connectButton.isHidden = false
                
                self.player.removeAllActions()
                self.player.removeFromParent()
                
                self.timer?.invalidate()
                self.timer = nil
                self.isConnected = false
                self.connectedDate = nil
                
                self.arenaView.hrv.text = "--"
                self.arenaView.time.text = "--"
                self.arenaView.setChart([])
                
                self.rings.forEach( {$0.isHidden = true })
            }
            
        }
    
    @objc func updateTimer()
    {
        if let startDate = self.connectedDate
        {
            let timeElapsed = abs(startDate.timeIntervalSinceNow)
            
            self.arenaView.time.text = timeElapsed.stringZendoTimeWatch
        }
    }
    
    @objc func progress(notification: NSNotification)
    {
        if let progress = notification.object as? [String]
        {
            let lastProgress = progress.last!.description.lowercased().contains("good")
            
            if (ring >= 2)
            {
                DispatchQueue.main.async
                {
                    self.player.removeAllActions()
                    self.player.removeFromParent()
                    
                    self.ring = 0
                    
                    if let shell = self.spriteView.scene!.childNode(withName: "//0")! as? SKShapeNode {
                        
                        shell.addChild(self.player)
                        
                        self.player.zPosition = 3.0
                        
                        let action = SKAction.repeatForever( SKAction.follow(shell.path!, asOffset: false, orientToPath: true, speed: 25.0))
                        
                        self.player.run(action)
                    }
                }
            }
            else if(lastProgress && ring < 2)
            {
                self.ring = self.ring + 1
                
                DispatchQueue.main.async
                {
                    self.player.removeAllActions()
                    self.player.removeFromParent()
                        
                    if let shell = self.spriteView.scene!.childNode(withName: "//" + self.ring.description)! as? SKShapeNode
                    {
                        shell.addChild(self.player)
                        
                        let action = SKAction.repeatForever( SKAction.follow(shell.path!, asOffset: false, orientToPath: true, speed: 15.0))
                        
                        self.player.run(action)
                    }
                }
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
            
            
            DispatchQueue.main.async
            {
                //#todo: update the whole hud view like this
                self.arenaView.hrv.text = text_hrv
                
                self.chartHR[String(Date().timeIntervalSince1970)] = int_hr
            
                let chartHR = self.chartHR.sorted(by: <)

                self.arenaView.setChart(chartHR)
                
            }
        }
        
    }
    
    func setupScene() -> SKScene
    {
        spriteView.frame = UIScreen.main.bounds
        
        let scene = SKScene(size: (spriteView.frame.size))
        scene.scaleMode = .aspectFill
        
        self.startBackgroundContent(story: story, completion:
        {
            item in
            
            DispatchQueue.main.async
            {
                self.videoPlayer = AVPlayer(playerItem: item)
                let video = SKVideoNode(avPlayer: self.videoPlayer)
                video.zPosition = 1.0
                video.size = scene.frame.size
                video.position = scene.position
                video.anchorPoint = scene.anchorPoint
                video.play()
                scene.addChild(video)
    
            }
            
        })
    
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: videoPlayer.currentItem, queue: nil)
        {
            notification in
            
            DispatchQueue.main.async
            {
                self.videoPlayer.seek(to: kCMTimeZero)
                self.videoPlayer.play()
            }
                        
        }
        
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
        spriteView.addGestureRecognizer(panGR)
        
        setupConnectButton()
        
        self.addShell(scene, 30, "2")
        self.addShell(scene, 90, "1")
        self.addShell(scene, 150, "0")
        
        return scene
        
    }
    
    func addShell(_ parent: SKNode, _ radius: Int, _ name: String)
    {
  
        let pathNode = SKShapeNode(circleOfRadius: CGFloat(radius))
        
        pathNode.strokeColor = SKColor.zenWhite
        
        pathNode.position = CGPoint(x: parent.frame.midX, y: parent.frame.midY)
        
        pathNode.fillColor = SKColor(red:0.06, green:0.15, blue:0.13, alpha:0.3)
       
        pathNode.zPosition = 3
        
        pathNode.name = name
        
        pathNode.isHidden = true
        
        pathNode.lineWidth = CGFloat(0.01)
        
        parent.addChild(pathNode)
        
        rings.append(pathNode)
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
            if progress + panGR.velocity(in: nil).y / view.bounds.height > 0.3 {
                
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }
}

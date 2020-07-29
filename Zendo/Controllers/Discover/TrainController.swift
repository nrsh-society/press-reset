//
//  ViewController.swift
//  zendō arena
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
import SwiftyJSON

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
    
    let player = SKSpriteNode(imageNamed: "player1")
    var ring: Int = 0
    var story: Story!
    var idHero = ""
    var panGR: UIPanGestureRecognizer!
    var showLevels : Bool = false
    var showGroups : Bool = false
    var airplay: AirplayController?
    var chartHR = [String: Int]()
    var rings = [SKShapeNode]()
    var scene : SKScene?
    
    let diskConfig = DiskConfig(name: "DiskCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    
    lazy var storage: Cache.Storage? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()
    
    static func loadFromStoryboard(_ showLevels: Bool, _ showGroups: Bool = false) -> TrainController
    {
       let controller = UIStoryboard(name: "TrainController", bundle: nil).instantiateViewController(withIdentifier: "TrainController") as! TrainController
        
        controller.showLevels = showLevels
        controller.showGroups = showGroups
        
        return controller
        
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        try? storage?.removeAll()
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
        
        Mixpanel.mainInstance().track(event: "phone_lab", properties: ["name": story.title])
        
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
        
        Mixpanel.mainInstance().time(event: "phone_lab")
        
        setupWatchNotifications()
        
        do {
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        
        modalPresentationCapturesStatusBarAppearance = true
        
        self.scene = self.setupScene()
        
        self.spriteView.presentScene(scene)
        
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
        if(Settings.isSensorConnected)
        {
            Mixpanel.mainInstance().time(event: "phone_lab_watch_connected")
            
            let scene = self.spriteView.scene!
            
            DispatchQueue.main.async
            {
                UIView.animate(withDuration: 0.5)
                {
                    self.arenaView.isHidden = false
                    self.connectButton.isHidden = true
                }

                if(self.showLevels)
                {
                    self.rings.forEach( {$0.isHidden = false })
                    
                    if let shell = scene.childNode(withName: "//0")! as? SKShapeNode
                    {
                        shell.addChild(self.player)
                        
                        self.player.zPosition = 3.0
                        
                        //let emitter = SKEmitterNode(fileNamed: "trainparticles.sks")!
                        
                        //emitter.targetNode = shell
                        
                        //emitter.zRotation = self.player.zRotation
        
                        //self.player.addChild(emitter)
                        
                        let action = SKAction.repeatForever(SKAction.follow(shell.path!, asOffset: false, orientToPath: true, speed: 15.0))
                        
                        self.player.run(action)
                       
                    }
                    
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
                self.player.removeAllActions()
                
                UIView.animate(withDuration: 0.5)
                {
                    self.player.removeFromParent()
                    self.arenaView.isHidden = true
                    self.connectButton.isHidden = false
                    self.rings.forEach( {$0.isHidden = true })
                    
                    self.arenaView.hrv.text = "--"
                    self.arenaView.time.text = "--"
                    self.arenaView.setChart([])
                }
                
                let vc = ResultGameController.loadFromStoryboard()
                self.present(vc, animated: true)
                
        }
        
    }
    
    @objc func progress(notification: NSNotification)
    {
        if let progress = notification.object as? String
        {
            let lastProgress = progress.description.lowercased().contains("true")
            
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
            
             Hero.shared.finish()
            
        }

    }
}



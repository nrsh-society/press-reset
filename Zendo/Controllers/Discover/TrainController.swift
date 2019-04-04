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
    var joint : SKPhysicsJointSpring?
    var ring: Int = 0
    var story: Story!
    var video: SKVideoNode?
    var idHero = ""
    var timer: Timer?
    var videoPlayer = AVPlayer()
    let size = CGSize(width: 30 , height: 30)
    var panGR: UIPanGestureRecognizer!
    var showLevels : Bool = false
    var airplay: AirplayController?
    
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
                                               name: NSNotification.Name("sample"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.progress),
                                               name: NSNotification.Name("progress"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(startSession),
                                               name: .startSession,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateHR),
                                               name: .updateHRV,
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
        
        startSession()
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
        DispatchQueue.main.async
        {
            if let _ = Settings.timeSession {
                Mixpanel.mainInstance().time(event: "phone_train_watch_connected")
                self.updateHR()
                UIView.animate(withDuration: 0.3) {
                    self.arenaView.alpha = 1.0
                    self.arenaView.isHidden = false
                    self.connectButton.isHidden = true
                }
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)

            } else {
                
                Mixpanel.mainInstance().track(event: "phone_train_watch_connected", properties: ["name": self.story.title])
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.arenaView.alpha = 1.0
                    self.arenaView.isHidden = true
                    self.connectButton.isHidden = false

                }, completion: { completion in
                    DispatchQueue.main.async {

                        self.timer?.invalidate()
                        self.timer = nil

                        self.arenaView.hrv.text = "--"
                        self.arenaView.time.text = "--"
                        self.arenaView.setChart([])
                    }
                })

            }
        }
    }
    
    @objc func updateHR() {
        let chartHRV = Settings.chartHRV.sorted(by: <)
        
            DispatchQueue.main.async {
               
                self.arenaView.setChart(chartHRV)
            }
        
    }
    
    @objc func updateTimer() {
        if let startDate = Settings.timeSession {
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
                        self.spriteView.scene?.physicsWorld.removeAllJoints()
                        self.player.removeFromParent()
                }
            }
            else if(lastProgress && ring < 2)
            {
                self.ring = self.ring + 1
                
                DispatchQueue.main.async
                    {
                        
                        self.spriteView.scene?.physicsWorld.remove(self.joint!)
                        
                        if let shell = self.spriteView.scene!.childNode(withName: self.ring.description)! as? SKShapeNode {
                            
                            self.player.position = CGPoint(x: shell.frame.maxX  + cos((CGFloat(1) * 200 + self.size.width)  ) , y: shell.frame.midY + sin(CGFloat(1) * 200 +  self.size.width))
                            
                            self.player.zRotation = 0
                            
                            let playBody = self.player.physicsBody!
                            
                            playBody.velocity = CGVector(dx: 0, dy: -16.5)
                            
                            let center = self.spriteView.scene!.childNode(withName: "center")!
                            
                            let centerBody = center.physicsBody!
                            
                            self.joint = SKPhysicsJointSpring.joint(withBodyA: centerBody
                                , bodyB: self.player.physicsBody!
                                , anchorA: center.position
                                , anchorB: self.player.position)
                            
                            self.joint?.frequency = 1.0
                            self.joint?.damping = 0.0
                            
                            self.spriteView.scene?.physicsWorld.add(self.joint!)
                            
                        }
                }
            }
            
        }
        
        
    }
    
    @objc func sample(notification: NSNotification)
    {
        if let sample = notification.object as? [String : Any]
        {
            let text_hrv = sample["sdnn"] as! String
            let double_hrv = Double(text_hrv)!.rounded()
            let hrv = Float(double_hrv)
            let text = Int(hrv.rounded()).description
            
            DispatchQueue.main.async
            {
                //#todo: update the whole hud view like this
                self.arenaView.hrv.text = text
            }
        }
        
    }
    
    func setupScene() -> SKScene
    {
        spriteView.frame = UIScreen.main.bounds
        
        let scene = SKScene(size: (spriteView.frame.size))
        scene.scaleMode = .aspectFill
        
        scene.physicsBody = SKPhysicsBody(edgeLoopFrom: scene.frame)
        scene.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        scene.physicsBody?.node?.name = "walls"
        scene.physicsBody?.isDynamic = false
        scene.physicsBody?.friction = 0
        scene.physicsBody?.linearDamping = 0
        
        self.startBackgroundContent(story: story, completion:
        {
            item in
    
            self.videoPlayer = AVPlayer(playerItem: item)
            let video = SKVideoNode(avPlayer: self.videoPlayer)
        
            video.size = scene.frame.size
            video.position = scene.position
            video.anchorPoint = scene.anchorPoint
            video.play()
            scene.addChild(video)
        })
    
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem, queue: nil) { notification in
            
            self.videoPlayer.seek(to: kCMTimeZero)
            self.videoPlayer.play()
                        
        }
        
        let size = CGSize(width: 1 , height: 1)
        let radius = (size.width / 2)
        let node = SKSpriteNode(imageNamed: "shobogenzo")
        
        node.size = size
        
        node.name = "center"
        
        let center = SKPhysicsBody(circleOfRadius: radius)
        center.affectedByGravity = false
        center.mass = 5.972e24 //1.989e30
        node.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY)
        node.physicsBody = center
        center.pinned = true
        scene.addChild(node)
        
        let field = SKFieldNode.radialGravityField()
        field.strength = 20.0
        field.falloff = 0
        field.name = "centerField"
        field.isEnabled = false
        field.position = node.position
        node.addChild(field)
        
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
        spriteView.addGestureRecognizer(panGR)
        
        setupConnectButton()
        
        if(self.showLevels)
        {
        
            self.addShell(scene, 30, "2")
            self.addShell(scene, 90, "1")
            self.addShell(scene, 150, "0")
        }
        
        return scene
        
    }
    
    func addShell(_ scene: SKScene, _ radius: Int, _ name: String)
    {
        let bezierPath = UIBezierPath(arcCenter: CGPoint(x: scene.frame.midX, y: scene.frame.midY), radius: CGFloat(radius), startAngle: 0 , endAngle: CGFloat(Double.pi) * 2.0, clockwise: true)
        
        let pathNode = SKShapeNode(path: bezierPath.cgPath)
        pathNode.strokeColor = SKColor.clear
        
        let level = Float(Int(name)! * 2 )
        let realLevel = CGFloat(level / 100)
        pathNode.glowWidth = realLevel
        //pathNode.alpha = floatLevel
        
        pathNode.name = name
        
        pathNode.lineWidth = CGFloat(0.01 + realLevel)
        
        scene.addChild(pathNode)
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

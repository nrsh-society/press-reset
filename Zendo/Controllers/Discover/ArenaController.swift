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


class ArenaController: UIViewController
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
    
    var players = [String : SKSpriteNode]()
    var joints = [String : SKPhysicsJointSpring]()
    var rings = [String : Int]()
    var connectedPlayerCount = 0
    var story: Story!
    var video: SKVideoNode?
    var idHero = ""
    var timer: Timer?
    var player = AVPlayer()
    let size = CGSize(width: 30 , height: 30)
    var multiPlayer = false
    var panGR: UIPanGestureRecognizer!
    
    static func loadFromStoryboard( _ multiPlayer : Bool) -> ArenaController
    {
       let controller = UIStoryboard(name: "ArenaController", bundle: nil).instantiateViewController(withIdentifier: "ArenaController") as! ArenaController
        
        controller.multiPlayer = multiPlayer
        
        return controller
        
    }
    
    var airplay: AirplayController?
    
    func airplay(_ url: URL)
    {
        if let airplay = self.airplay
        {
            airplay.dismiss()
            airplay.dismiss(animated: true, completion: nil)
        }
        
        self.airplay = AirplayController.loadFromStoryboard(url)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "phone_train", properties: ["name": story.title])
        
        NotificationCenter.default.removeObserver(self)
        
        if(self.multiPlayer)
        {
            Cloud.unregisterChangeHandlers()
        }
        
        video?.pause()
        spriteView.scene?.removeAllChildren()
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        self.airplay?.dismiss()
        self.airplay = nil
        
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        Mixpanel.mainInstance().time(event: "phone_train")
        
        if(self.multiPlayer)
        {
        
            Cloud.registerSamplesChangedHandler()
                {
                    (samples, error) in
                    
                    self.processSamples(samples)
                    
            }
        
            Cloud.registerProgressChangedHandler()
                {
                    (progress, error) in
                    
                    self.processProgress(progress)
                    
            }
        }
        
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
        
        
        
        modalPresentationCapturesStatusBarAppearance = true
        
        self.spriteView.presentScene(self.setupScene())
        
        self.connectButton.addTarget(self, action: #selector(connectAppleWatch), for: .primaryActionTriggered)
        
        self.connectButton.layer.borderColor = UIColor.white.cgColor
        self.connectButton.layer.borderWidth = 1.0
        self.connectButton.layer.cornerRadius = 10.0
        self.connectButton.backgroundColor = UIColor(red:0.06, green:0.15, blue:0.13, alpha:0.3)
        self.connectButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.connectButton.layer.shadowColor = UIColor(red:0, green:0, blue:0, alpha:0.5).cgColor
        self.connectButton.layer.shadowOpacity = 1
        self.connectButton.layer.shadowRadius = 20

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
            if(self.multiPlayer)
            {
                Cloud.updateProgress(email: Settings.email!, content: "arena", progress: progress)
            }
            else
            {
                let value = ["data" : progress,
                             "updated" : Date().timeIntervalSince1970.description,
                             "content" : "",
                             "email" : Settings.email!] as [String : Any]
                
                self.processProgress([Settings.email!: value as Dictionary<String, AnyObject>])
            }
        }
        
    }
    
    @objc func sample(notification: NSNotification)
    {
        if let sample = notification.object as? [String : Any]
        {
            if(self.multiPlayer)
            {
                Cloud.updateSample(email: Settings.email!, content: "arena", sample: sample)
            }
            else
            {
                let value = ["data" : sample,
                             "updated" : Date().description,
                             "content" : "",
                             "email" : Settings.email!] as [String : Any]
                
                
                self.processSamples([Settings.email!: value as Dictionary<String, AnyObject>])
            }
        }
    }
    
    func getDate(_ text : String) -> Date
    {
        return Date(timeIntervalSince1970: Double(text)!)
    }
    
    func processProgress(_ progress:  [String : [String : AnyObject]])
    {
        progress.forEach(
            {
                (sample) in
                
                let ( _, value) = sample
                
                let email = value["email"]! as! String
                let player = self.players[email]
                let join = self.joints[email]
                let ring = self.rings[email]
                
                if let existingPlayer = player, let existingJoint = join, var currentRing = ring
                {
                    let text_updated = value["updated"] as! String
                    let date_updated = getDate(text_updated)
                    let since_now = date_updated.timeIntervalSinceNow
                    
                    let progress = (value["data"]! as! [String]).last!.description.lowercased().contains("good")
                    
                    if (progress && since_now > (-60) && currentRing >= 2)
                    {

                        //#todo: are all players
                        //let playersOnFinalRing = self.rings.map( { $1.value >= 2 } )
                        let playersOnFinalRing =  self.rings.compactMap({ (arg0) -> String? in
                            
                            let (key, value) = arg0
                            if (value >= 2)
                            {
                                return key
                                
                            }
                            else
                            {
                                return nil
                            }
                            
                        })

                        
                        if playersOnFinalRing.count == self.players.count
                        {
                            
                            self.players.forEach({
                                (arg0) in
                                
                                let (key, value) = arg0
                                
                                DispatchQueue.main.async
                                    {
                                        self.spriteView.scene?.physicsWorld.removeAllJoints()
                                        //self.spriteView.scene?.physicsWorld.remove(existingJoint)
                                        //existingPlayer.removeFromParent()
                                        value.removeFromParent()
                                        self.players.removeValue(forKey: key)
                                        self.joints.removeValue(forKey: key)
                                        self.rings.removeValue(forKey: key)
                                }
                                
                                return
                                
                            })
                            
                            }
                        
                    }
                    else if(progress && since_now > (-60) && currentRing < 2)
                    {
                        self.rings[email] = currentRing + 1
                        
                        DispatchQueue.main.async
                            {
                                
                                self.spriteView.scene?.physicsWorld.remove(existingJoint)
                                
                                if let shell = self.spriteView.scene!.childNode(withName: self.rings[email]!.description)! as? SKShapeNode {
                                
                                existingPlayer.position = CGPoint(x: shell.frame.maxX  + cos((CGFloat(self.players.count) * 200 + self.size.width)  ) , y: shell.frame.midY + sin(CGFloat(self.players.count) * 200 +  self.size.width))
                                
                                existingPlayer.zRotation = 0
                                
                                let playBody = existingPlayer.physicsBody!
                                
                                playBody.velocity = CGVector(dx: 0, dy: -16.5)
                                
                                let center = self.spriteView.scene!.childNode(withName: "center")!
                                
                                let centerBody = center.physicsBody!
                                
                                let joint = SKPhysicsJointSpring.joint(withBodyA: centerBody
                                    , bodyB: existingPlayer.physicsBody!
                                    , anchorA: center.position
                                    , anchorB: existingPlayer.position)
                                
                                joint.frequency = 1.0
                                joint.damping = 0.0
                                
                                self.spriteView.scene?.physicsWorld.add(joint)
                                self.joints[email] = joint
                                }
                        }
                        
                    }
                }
        })
    }
    
    func processSamples(_ samples:  [String : [String : AnyObject]])
    {
        samples.forEach(
            {
                (sample) in
                
                let (_, value) = sample
                
                let data = value["data"] as! [String : String]
                
                let text_updated = data["time"]!
                let date_updated = getDate(text_updated)
                let since_now = date_updated.timeIntervalSinceNow
                
                if(since_now > (-60 * 5))
                {
                    let data = value["data"] as! [String : String]
                    
                    let text_hrv = data["sdnn"]!
                    let double_hrv = Double(text_hrv)!.rounded()
                    let hrv = Float(double_hrv)
                    
                    let email = value["email"]! as! String
                    
                    let player = self.players[email]
                    
                    let isPlayer1 = Settings.email?.elementsEqual(email)
                    
                    let text = Int(hrv.rounded()).description
                    
                    DispatchQueue.main.async
                    {
                    
                        self.arenaView.hrv.text = text
                        
                    }
                }
        })
    }
        
        /*
                    
                    if let existingPlayer = player
                    {
                       
                        let motion = data["motion"]!
                        let motionD = Double(motion)!
                                
                        if(motionD > 0.0)
                        {
                            existingPlayer.run(SKAction.applyAngularImpulse(CGFloat(motionD)
                                        , duration: 1))
                                    
                        }
                    }
                    else
                    {
                        
                        DispatchQueue.main.async
                        {
                            let radius = (self.size.width / 2)
                        
                            var node: SKSpriteNode
                                
                        if(isPlayer1!)
                        {
                            node = SKSpriteNode(imageNamed: "player1")
                        }
                        else
                        {
                            node = SKSpriteNode(imageNamed: "shobogenzo")
                        }
                        
                        node.size = self.size
                        
                        node.name = "ball"
                        
                        let body = SKPhysicsBody(circleOfRadius: radius)
                        
                        body.isDynamic = true
                        body.affectedByGravity = true
                        body.allowsRotation = true
                        body.mass = 100
                        body.friction = 0
                        body.linearDamping = 0
                        body.restitution = 1
                        
                        let ballCategory: UInt32 = 0x1 << 1
                        
                        body.categoryBitMask = ballCategory
                        body.contactTestBitMask = ballCategory
                        
                        node.physicsBody = body
                                
                        /*
                        
                        let text = Int(hrv.rounded()).description
                
                        let label = SKLabelNode(text: text)
                        
                        label.fontSize = 12
                        label.fontName = "Antenna"
                        label.fontColor = SKColor.yellow
                        label.verticalAlignmentMode = .center
                        label.horizontalAlignmentMode = .center
                        label.name = "hrv"
                        
                        node.addChild(label)
 
                        */
                        self.players[email] = node
                        
                        body.velocity = CGVector(dx: 0, dy: -16.5)
                        
                                self.spriteView.scene?.addChild(self.players[email]!)
                        
                        let dShell = self.spriteView.scene!.childNode(withName: "0")! as! SKShapeNode
                        
                                node.position = CGPoint(x: dShell.frame.maxX  + cos((CGFloat(self.players.count) * 200 + self.size.width)  ) , y: dShell.frame.midY + sin(CGFloat(self.players.count) * 200 +  self.size.width))
                        
                        let center = self.spriteView.scene!.childNode(withName: "center")!
                        
                        let centerBody = center.physicsBody!
                        
                        let joint = SKPhysicsJointSpring.joint(withBodyA: centerBody
                            , bodyB: body
                            , anchorA: center.position
                            , anchorB: node.position)
                        
                        joint.frequency = 5.0
                        joint.damping = 0.0
                        
                        self.spriteView.scene?.physicsWorld.add(joint)
                        
                        self.joints[email] = joint
                        
                        self.rings[email] = 0
                                
                        }
                        
                    }
                    
                }
                
        })*/
        
   // }
    
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
        
        let item = AVPlayerItem(url: URL(string: self.story.content[0].download!)!)
        
        player = AVPlayer(playerItem: item)
        video = SKVideoNode(avPlayer: player)
        
        video?.size = scene.frame.size
        video?.position = scene.position
        video?.anchorPoint = scene.anchorPoint
        scene.addChild(video!)
        video?.play()
        
        if let airplayURL = self.story.content[0].airplay, let url = URL(string: airplayURL)
        {
            self.airplay(url)
        }
    
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { notification in
            
            self.player.seek(to: kCMTimeZero)
            self.player.play()
                        
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
        
        self.addShell(scene, 30, "2")
        //self.addShell(scene, 50, "3")
        self.addShell(scene, 90, "1")
        //self.addShell(scene, 130, "1")
        self.addShell(scene, 150, "0")
        
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

extension ArenaController: SKPhysicsContactDelegate
{
    
    func didBegin(_ contact: SKPhysicsContact)
    {
        let lname = contact.bodyA.node?.name
        let rname = contact.bodyB.node?.name
        
        if(lname == rname &&  lname == "ball")
        {
            print(contact.collisionImpulse)
            
            if(contact.collisionImpulse < 10.0)
            {
                
                if(self.connectedPlayerCount == self.players.count)
                {
                    players.values.forEach
                        {
                            node in
                            
                            node.isHidden = true
                            node.removeFromParent()
                            
                    }
                    
                    players.removeAll()
                    
                    connectedPlayerCount = 0
                    
                    self.spriteView.scene?.physicsWorld.removeAllJoints()
                    
                }
                else
                {
                    connectedPlayerCount += 1
                }
            }
            else
            {
                let parentA = contact.bodyA.node?.parent
                let parentB = contact.bodyB.node?.parent
                
                if (parentA != nil && parentB != nil)
                {
                    let joint = SKPhysicsJointSpring.joint(withBodyA: contact.bodyA
                        , bodyB: contact.bodyB
                        , anchorA: contact.contactPoint
                        , anchorB: contact.contactPoint)
                    
                    joint.frequency = 1.0
                    joint.damping = 0.0
                    
                    self.spriteView.scene?.physicsWorld.add(joint)
                }
            }
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact)
    {
        print(contact.collisionImpulse)
        
        let lname = contact.bodyA.node?.name
        let rname = contact.bodyB.node?.name
        
        if(lname == rname &&  lname == "ball")
        {
            print(contact.collisionImpulse)
        }
    }
}


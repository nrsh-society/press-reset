//
//  AirplayController.swift
//  Harness
//
//  Created by Douglas Purdy on 1/19/19.
//  Copyright © 2019 Douglas Purdy. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Firebase
import FirebaseDatabase
import SpriteKit

class AirplayController: UIViewController
{
    
    @IBOutlet weak var gameView: SKView!
    @IBOutlet weak var tickerLabel: UILabel!
    
    var screenConnectObserver : Any?
    var screenDisconnectObserver : Any?
    
    var newWindow : UIWindow?
    var avItem : AVPlayerItem?
    var avLayer : AVPlayerLayer?
    var avPlayer : AVPlayer?
    var url : URL?
    var players = [String : SKSpriteNode]()
    var joints = [String : SKPhysicsJointSpring]()
    var rings = [String : Int]()
    let size = CGSize(width: 15 , height: 15)
    
    class func loadFromStoryboard(_ url: URL) -> AirplayController
    {
        let storyboard =  UIStoryboard(name: "AirplayController", bundle: nil).instantiateViewController(withIdentifier: "AirplayController") as! AirplayController
        
        storyboard.url = url
        storyboard.setupDisplayCallbacks(url: url)
        
        return storyboard
 
    }
    
    func setupDisplayCallbacks(url: URL)
    {
        if(screenConnectObserver == nil)
        {
            screenConnectObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name.UIScreenDidConnect,
                object: nil, queue: nil)
            {
                (notification) in
                
                let newScreen = notification.object as! UIScreen
                
                if self.newWindow == nil
                {
                    let screenDimensions = newScreen.bounds
                    
                    self.newWindow = UIWindow(frame: screenDimensions)
                    self.newWindow?.screen = newScreen
                
                    self.newWindow?.rootViewController = self
                
                    self.newWindow?.isHidden = false
                
                }
            
                NotificationCenter.default.removeObserver(self.screenConnectObserver!)
                
                self.screenConnectObserver = nil
            }
            
        }
        
        if(screenDisconnectObserver == nil)
        {
    
            screenDisconnectObserver = NotificationCenter.default.addObserver(
                forName:NSNotification.Name.UIScreenDidDisconnect,
                object: nil, queue: nil)
            {
                (notification) in
                

                let _ = notification.object as! UIScreen
                
                if self.newWindow != nil
                {
                    self.dismiss()
                }
                
                NotificationCenter.default.removeObserver(self.screenDisconnectObserver!)
                
                self.screenDisconnectObserver = nil
            }
        }
    }
    
    func dismiss()
    {
        if let observer = self.screenConnectObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observer = self.screenDisconnectObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
        
        self.avPlayer?.pause()
        self.dismiss(animated: true)
        self.newWindow?.isHidden = true
        self.newWindow = nil
        
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        self.avPlayer?.pause()
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.gameView.presentScene(self.setupScene())
        
        UIApplication.shared.isIdleTimerDisabled = true
        
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
        
        /*
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sample),
                                               name: NSNotification.Name("sample"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.progress),
                                               name: NSNotification.Name("progress"),
                                               object: nil)
        */
        
    }
    
    @objc func progress(notification: NSNotification)
    {
        if let progress = notification.object as? [String]
        {
            Cloud.updateProgress(email: Settings.email!, content: "arena", progress: progress)
        }
    }
    
    func updateTicker(text: String)
    {
        self.tickerLabel.text = text
    }
    
    @objc func sample(notification: NSNotification)
    {
        if let sample = notification.object as? [String : Any]
        {
            Cloud.updateSample(email: Settings.email!, content: "arena", sample: sample)
        }
    }
    
    func setupScene() -> SKScene
    {
        gameView.frame = UIScreen.main.bounds
        
        let scene = SKScene(size: (gameView.frame.size))
        
        scene.scaleMode = .aspectFill
        
        scene.physicsBody = SKPhysicsBody(edgeLoopFrom: scene.frame)
        scene.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        scene.physicsBody?.node?.name = "walls"
        scene.physicsBody?.isDynamic = false
        scene.physicsBody?.friction = 0
        scene.physicsBody?.linearDamping = 0
        
        let item = AVPlayerItem(url: self.url!)
        
        let player = AVPlayer(playerItem: item)
        let video = SKVideoNode(avPlayer: player)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: nil) { notification in
            
            player.seek(to: kCMTimeZero)
            player.play()
            
        }
        
        video.size = scene.frame.size
        video.position = scene.position
        video.anchorPoint = scene.anchorPoint
        scene.addChild(video)
        video.play()
        
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
        
        
        self.addShell(scene, 30, "2")
       
        self.addShell(scene, 60, "1")
        
        self.addShell(scene, 90, "0")
        
        return scene
        
    }
    
    func addShell(_ scene: SKScene, _ radius: Int, _ name: String)
    {
        let bezierPath = UIBezierPath(arcCenter: CGPoint(x: scene.frame.midX, y: scene.frame.midY), radius: CGFloat(radius), startAngle: 0 , endAngle: CGFloat(Double.pi) * 2.0, clockwise: true)
        
        let pathNode = SKShapeNode(path: bezierPath.cgPath)
        pathNode.strokeColor = SKColor.white
        
        let level = Float(Int(name)! * 2 )
        let realLevel = CGFloat(level / 100)
        pathNode.glowWidth = realLevel
        
        
        pathNode.name = name
        
        pathNode.lineWidth = CGFloat(0.01 + realLevel)
        
        scene.addChild(pathNode)
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
                                        self.gameView.scene?.physicsWorld.removeAllJoints()
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
                                
                                self.gameView.scene?.physicsWorld.remove(existingJoint)
                                
                                if let shell = self.gameView.scene!.childNode(withName: self.rings[email]!.description)! as? SKShapeNode {
                                    
                                    existingPlayer.position = CGPoint(x: shell.frame.maxX  + cos((CGFloat(self.players.count) * 200 + self.size.width)  ) , y: shell.frame.midY + sin(CGFloat(self.players.count) * 200 +  self.size.width))
                                    
                                    existingPlayer.zRotation = 0
                                    
                                    let playBody = existingPlayer.physicsBody!
                                    
                                    playBody.velocity = CGVector(dx: 0, dy: -16.5)
                                    
                                    let center = self.gameView.scene!.childNode(withName: "center")!
                                    
                                    let centerBody = center.physicsBody!
                                    
                                    let joint = SKPhysicsJointSpring.joint(withBodyA: centerBody
                                        , bodyB: existingPlayer.physicsBody!
                                        , anchorA: center.position
                                        , anchorB: existingPlayer.position)
                                    
                                    joint.frequency = 1.0
                                    joint.damping = 0.0
                                    
                                    self.gameView.scene?.physicsWorld.add(joint)
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
                    
                    if let existingPlayer = player
                    {
                        DispatchQueue.main.async
                            {
                                
                                let motion = data["motion"]!
                                let motionD = Double(motion)!
                                
                                if(motionD > 0.0)
                                {
                                    existingPlayer.run(SKAction.applyAngularImpulse(CGFloat(motionD)
                                        , duration: 1))
                                    
                                }
                                
                                let text = Int(hrv.rounded()).description
                                
                                let label = existingPlayer.childNode(withName: "hrv") as? SKLabelNode
                                
                                label?.text = text

                        }
                    }
                    else
                    {
                        
                        DispatchQueue.main.async
                            {
                                
                                let radius = ((self.size).width / 2)
                                
                                var node: SKSpriteNode
                                
                                node = SKSpriteNode(imageNamed: "shobogenzo")
                                
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
                                
                                 let text = Int(hrv.rounded()).description
                                 
                                 let label = SKLabelNode(text: text)
                                 
                                 label.fontSize = 8
                                 label.fontName = "Antenna"
                                 label.fontColor = SKColor.zenWhite
                                 label.verticalAlignmentMode = .center
                                 label.horizontalAlignmentMode = .center
                                 label.name = "hrv"
                                 
                                 node.addChild(label)
                                
                                self.players[email] = node
                                
                                body.velocity = CGVector(dx: 0, dy: -16.5)
                                
                                self.gameView.scene?.addChild(self.players[email]!)
                                
                                let dShell = self.gameView.scene!.childNode(withName: "0")! as! SKShapeNode
                                
                                node.position = CGPoint(x: dShell.frame.maxX  + cos((CGFloat(self.players.count) * 200 + self.size.width)  ) , y: dShell.frame.midY + sin(CGFloat(self.players.count) * 200 +  self.size.width))
                                
                                let center = self.gameView.scene!.childNode(withName: "center")!
                                
                                let centerBody = center.physicsBody!
                                
                                let joint = SKPhysicsJointSpring.joint(withBodyA: centerBody
                                    , bodyB: body
                                    , anchorA: center.position
                                    , anchorB: node.position)
                                
                                joint.frequency = 5.0
                                joint.damping = 0.0
                                
                                self.gameView.scene?.physicsWorld.add(joint)
                                
                                self.joints[email] = joint
                                
                                self.rings[email] = 0
                                
                        }
                        
                    }
                    
                }
                
        })
        
    }
    
}

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


class ArenaController: UIViewController
{
    @IBOutlet weak var spriteView: SKView!
    
    var players = [String : SKSpriteNode]()
    var connectedPlayerCount = 0
    var story: Story!
    var video : SKVideoNode?
    var idHero = ""
    
     var panGR: UIPanGestureRecognizer!
    
    static func loadFromStoryboard() -> ArenaController {
        return UIStoryboard(name: "ArenaController", bundle: nil).instantiateViewController(withIdentifier: "ArenaController") as! ArenaController
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
         NotificationCenter.default.removeObserver(self)
        video?.pause()
        spriteView.scene?.removeAllChildren()
        
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Cloud.registerSamplesChangedHandler()
        {
            (samples, error) in
            
            self.processSamples(samples)
            
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sample),
                                               name: NSNotification.Name("sample"),
                                               object: nil)
        
        modalPresentationCapturesStatusBarAppearance = true
        
        self.spriteView.presentScene(self.setupScene())
    }
    
    
    @objc func sample(notification: NSNotification)
    {
        if let sample = notification.object as? [String : Any]
        {
            Cloud.updateSample(email: Settings.email!, content: "area", sample: sample)
        }
    }
    
    
    func processSamples(_ samples:  [String : [String : AnyObject]])
    {

            samples.forEach(
                {
                    (sample) in
                    
                    let (key, value) = sample
                    
                    let data = value["data"] as! [String : String]
                    
                    let text_hrv = data["sdnn"]!
                    let double_hrv = Double(text_hrv)!.rounded()
                    let hrv = Float(double_hrv)
                    
                    let email = value["email"]! as! String
                    
                    let player = self.players[email]
                    
                    DispatchQueue.main.async
                    {
                        if let existingPlayer = player
                        {
                            let label = existingPlayer.childNode(withName: "hrv") as! SKLabelNode
                            
                            label.text = Int(hrv).description
                            label.fontSize = 55
                            
                            let size = CGSize(width: 100 + (CGFloat(hrv) * 1.1 ), height: 100 + (CGFloat(hrv) * 1.1 ))
                            
                            existingPlayer.size = size
                            
                            let radius = ((100 + CGFloat(hrv)) / 2)
                            
                            let newBody = SKPhysicsBody(circleOfRadius: radius)
                            
                            newBody.velocity = (existingPlayer.physicsBody?.velocity)!
                            newBody.mass = 100 + CGFloat(hrv)
                            newBody.friction = CGFloat(hrv * 0.01)
                            newBody.restitution = 1 //- CGFloat(hrv * 0.01)
                            newBody.linearDamping = CGFloat(hrv * 0.01)
                            newBody.allowsRotation = false
                            newBody.affectedByGravity = false //!((existingPlayer.physicsBody?.affectedByGravity)!)
                            
                            
                            let ballCategory  : UInt32 = 0x1 << 1
                            
                            newBody.categoryBitMask = ballCategory
                            newBody.contactTestBitMask = ballCategory
                            
                            existingPlayer.physicsBody = newBody

                                let yaw = data["yaw"]!
                                let pitch = data["pitch"]!
                               // let roll = value["roll"]! as! String
                                
                                let yawD = Double(yaw)!
                                let pitchD = Double(pitch)!
                                //let rollD = Double(roll)!
                        
                                let force = CGVector(dx: 30000 * pitchD, dy: 30000 * yawD)
                                
                                existingPlayer.physicsBody?.applyImpulse(force)

                        }
                        else
                        {
                                let size = CGSize(width: 100 , height: 100)
                            
                                let radius = (size.width / 2)
                                
                                let node = SKSpriteNode(imageNamed: "shobogenzo")
                                
                                node.size = size
                            
                                node.name = "ball"
                            
                                let body = SKPhysicsBody(circleOfRadius: radius / 2 )
                                
                                body.isDynamic = true
                                body.affectedByGravity = true
                                body.allowsRotation = false
                                body.mass = CGFloat(hrv)
                                body.friction = CGFloat(hrv * 0.01)
                                body.linearDamping = CGFloat(hrv * 0.01)
                                body.restitution = 1 //0.9 //1 - CGFloat(hrv * 0.01)
                            
                                node.physicsBody = body
                                
                                let text = Int(hrv.rounded()).description
                                
                                let label = SKLabelNode(text: text)
                                
                                label.fontSize = 33
                                label.fontName = "Antenna"
                                
                                label.verticalAlignmentMode = .center
                                label.horizontalAlignmentMode = .center
                                label.name = "hrv"
                            
                            
                                node.addChild(label)
                                
                            self.players[email] = node
                            
                            node.position = CGPoint(x: CGFloat(self.players.count) * CGFloat(radius * 2), y: 600)
                            body.velocity = CGVector(dx: 0, dy: 100)
                            self.spriteView.scene?.addChild(self.players[email]!)
                            
                        }
                            
                    }
                    
            })
        
    }
    
    func setupScene() -> SKScene
    {
        spriteView.frame = UIScreen.main.bounds
        
        let scene = SKScene(size: (spriteView.frame.size))
        scene.scaleMode = .aspectFill
        
        scene.physicsBody = SKPhysicsBody(edgeLoopFrom: scene.frame)
        scene.physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        scene.physicsWorld.contactDelegate = self
        scene.physicsBody?.node?.name = "walls"
        scene.physicsBody?.isDynamic = false
 
        video = SKVideoNode(url: URL(string: "http://media.zendo.tools/sitting_meditation.m4v")!)
        
        video?.size = scene.frame.size
        video?.position = scene.position
        video?.anchorPoint = scene.anchorPoint
        scene.addChild(video!)
        video?.play()
        
        let center = SKPhysicsBody(circleOfRadius: CGFloat(10.0))
        center.affectedByGravity = false
        center.density = 1000000
        
        scene.addChild(SKSpriteNode(color: .clear, size: CGSize(width: 10, height: 10)))
        
        
        
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
        spriteView.addGestureRecognizer(panGR)
        
        return scene
        
    }
    
    @objc func pan() {
        let translation = panGR.translation(in: nil)
        let progress = translation.y / spriteView.bounds.height
        switch panGR.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
            Hero.shared.apply(modifiers: [.position(currentPos)], to: spriteView)
        default:
            if progress + panGR.velocity(in: nil).y / spriteView.bounds.height > 0.3 {
              //  removeObserver()
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



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
                            
                            label.text = Int(hrv.rounded()).description
                            
                            let motion = data["motion"]!
                            let motionD = Double(motion)!

                            if(motionD > 0.0)
                            {
                               // let force = CGVector(dx: 100 * motionD, dy: 100 * motionD)
                                //existingPlayer.physicsBody?.applyImpulse(force)
                                
                               // let v = CGVector(dx: 0, dy: (existingPlayer.physicsBody?.velocity.dy)! + 75)
                                //existingPlayer.physicsBody?.velocity = v
                            }

                        }
                        else
                        {
                            let size = CGSize(width: 40 , height: 40)
                        
                            let radius = (size.width / 2)
                            
                            let node = SKSpriteNode(imageNamed: "shobogenzo")
                            
                            node.size = size
                        
                            node.name = "ball"
                        
                            let body = SKPhysicsBody(circleOfRadius: radius )
                            
                            body.isDynamic = true
                            body.affectedByGravity = true
                            body.allowsRotation = true
                            body.mass = 100
                            body.friction = 1
                            body.linearDamping = 0
                            body.restitution = 1
                            
                            let ballCategory  : UInt32 = 0x1 << 1
                            
                            body.categoryBitMask = ballCategory
                            body.contactTestBitMask = ballCategory
                            
                            node.physicsBody = body
                                
                            let text = Int(hrv.rounded()).description
                            
                            let label = SKLabelNode(text: text)

                            
                            label.fontSize = 15
                            label.fontName = "Antenna"
                            label.color = UIColor.black
                            label.verticalAlignmentMode = .center
                            label.horizontalAlignmentMode = .center
                            label.name = "hrv"
                            
                            node.addChild(label)
                            
                            self.players[email] = node
                            
                            node.position = CGPoint(x: self.spriteView!.frame.midX + (CGFloat(self.players.count) * radius * 1.1) , y: self.spriteView!.frame.midY + (CGFloat(self.players.count) * radius))
                            
                            body.velocity = CGVector(dx: 0, dy: 75)
                            
                            self.spriteView.scene?.addChild(self.players[email]!)
                            
                            let center = self.spriteView.scene!.childNode(withName: "center")!
                            
                            let centerBody = center.physicsBody!
                            
                            let joint = SKPhysicsJointSpring.joint(withBodyA: centerBody
                                , bodyB: body
                                , anchorA: center.position
                                , anchorB: node.position)
                            
                            joint.frequency = 5.0
                            joint.damping = 0.0
                            
                            self.spriteView.scene?.physicsWorld.add(joint)
                            
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
        scene.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        scene.physicsWorld.contactDelegate = self
        scene.physicsBody?.node?.name = "walls"
        scene.physicsBody?.isDynamic = false
        scene.physicsBody?.friction = 0
 
        video = SKVideoNode(url: URL(string: "http://media.zendo.tools/rainbow.mp4")!)
        
        video?.size = scene.frame.size
        video?.position = scene.position
        video?.anchorPoint = scene.anchorPoint
        scene.addChild(video!)
        video?.play()
        
        
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

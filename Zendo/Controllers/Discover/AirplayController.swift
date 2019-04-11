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
                notification in
                
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
        
    }
    
    @objc func progress(notification: NSNotification)
    {
        
    }
    
    @objc func sample(notification: NSNotification)
    {

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
        
        return scene
        
    }

}

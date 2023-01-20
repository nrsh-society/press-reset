//
//  GameController.swift
//  Zendo
//
//  Created by Douglas Purdy on 5/8/20.
//  Copyright © 2020 zenbf. All rights reserved.
//

import UIKit
import Hero
import SpriteKit
import HealthKit
import AVKit
import Mixpanel
import Cache
import AuthenticationServices
import Parse

class CommunityController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding
{
    var currentPlayers = [SKSpriteNode]()
    var notifyTimer : Timer?
    
    //#todo(debt): If we moved to SwiftUI can we get rid of some of this?
    var idHero = "" //not too sure what this does but it is store for the one of the dependencies that we have
    
    private let diskConfig = DiskConfig(name: "DiskCache")
    private let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    private lazy var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()
    
    var story: Story!
    
    
    @IBOutlet weak var sceneView: SKView!
    {
        didSet {
            
            sceneView.hero.id = idHero
            sceneView.frame = UIScreen.main.bounds
            sceneView.contentMode = .scaleAspectFill
            sceneView.backgroundColor = .clear
            sceneView.allowsTransparency = true
            
            let panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
            
            sceneView.addGestureRecognizer(panGR)
            
        }
    }
    
    
    
    @IBOutlet weak var connectButton: UIButton!
    {
        didSet
        {
            self.connectButton.addTarget(self, action: #selector(signIn), for: .primaryActionTriggered)
            
            self.connectButton.layer.borderColor = UIColor.white.cgColor
            self.connectButton.layer.borderWidth = 1.0
            self.connectButton.layer.cornerRadius = 10.0
            self.connectButton.backgroundColor = UIColor(red:0.06, green:0.15, blue:0.13, alpha:0.3)
            self.connectButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            self.connectButton.layer.shadowColor = UIColor(red:0, green:0, blue:0, alpha:0.5).cgColor
            self.connectButton.layer.shadowOpacity = 1
            self.connectButton.layer.shadowRadius = 20
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        self.sceneView.layer.zPosition = 0
        
        
    }
    
    static func loadFromStoryboard() -> CommunityController
    {
        let controller = UIStoryboard(name: "CommunityController", bundle: nil).instantiateViewController(withIdentifier: "CommunityController") as! CommunityController
        
        return controller
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "phone_lab", properties: ["name": story.title])
        
        NotificationCenter.default.removeObserver(self)
        
        UIApplication.shared.isIdleTimerDisabled = false
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        Mixpanel.mainInstance().time(event: "phone_lab")
        
        setBackground()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        self.sceneView.presentScene(self.getIntroScene())
        
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization){
        
        switch authorization.credential
        {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            
            let userIdentifier = appleIDCredential.user
            
            if let user = PFUser.current() {
                
            } else {
                
                PFUser.logInWithUsername(inBackground: userIdentifier, password: String(userIdentifier.prefix(9)))
                { user, error in
                    
                    if let user = user
                    {
                        print("login successful")
                    }
                    
                    if let error = error {
                        //create a new user for this AppleID
                        print(error)
                        
                    }
                }
                
            }
            
            
            break
            
        default:
            
            print("if you are seeing this it is too late")
            
        }
        
        self.start()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
    }
    
    func setupPhoneAV() {
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        modalPresentationCapturesStatusBarAppearance = true
        
        do {
            
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }
    
    @objc func pan(_ gestureRecognizer : UIPanGestureRecognizer)
    {
        let translation = gestureRecognizer.translation(in: nil)
        let progress = translation.y / view.bounds.height
        switch gestureRecognizer.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
            Hero.shared.apply(modifiers: [.position(currentPos)], to: view)
        default:
            Hero.shared.finish()
        }
        
    }
    
    @objc func signIn() {
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func start() {
        
        let main = self.getMainScene()
        
        self.sceneView.presentScene(nil) //don't ask, just invoke
        
        self.sceneView.presentScene(main)
        
        self.connectButton.isHidden = true
        
        self.loadPlayers()
        
    }
    
    @objc func loadPlayers()
    {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        let playerQuery = PFQuery(className: "Meditation")
        playerQuery.whereKeyExists("game_progress")
        playerQuery.whereKey("updatedAt", greaterThanOrEqualTo: oneMinuteAgo)
        
        playerQuery.findObjectsInBackground
        {
            objects, error in
            
            if let error = error
            {
                print (error)
            }
            
            if let objects = objects
            {
                DispatchQueue.main.async
                {
                    if (objects.count > 0)
                    {
                        self.hideNoPlayer()
                        
                        let scene = self.sceneView.scene!
                        
                        var index = 1
                        
                        var player : PlayerNode?
                        
                        for object in objects {
                            
                            let id = object["player"] as! String
                            let game_progress = object["game_progress"] as! String
                            
                            if let player = scene.childNode(withName: id) as? PlayerNode
                            {
                                player.updateProgress(progress: game_progress)
                                
                            }
                            else
                            {
                                player = PlayerNode()
                                player?.name = id
                                player?.updateProgress(progress: game_progress)
                                player?.zPosition = 3.0
                                scene.addChild(player!)
                                self.currentPlayers.append(player!)
                                
                            }
                            
                            if(index == 1)
                            {
                                player?.position = CGPoint(x: scene.frame.midX , y: scene.frame.midY)
                            }
                            else
                            {
                                let radians = 3.1415 * 2
                                let arc = radians / Double(objects.count)
                                let angle = arc * Double(index - 1)
                                let x = Double(scene.frame.midX) + 150 * cos(angle)
                                let y = Double(scene.frame.midY) + 150 * sin(angle)
                                
                                player?.position = CGPoint(x: x, y: y)
                            }
                            
                            index = index + 1
                        }
                    }
                    else
                    {
                        self.sceneView.scene!.removeChildren(in: self.currentPlayers)
                        self.showNoPlayers()
                    }
                }
            }
        }
        
        if(self.notifyTimer == nil)
        {
            self.notifyTimer = Timer.scheduledTimer(timeInterval: 10, target:self, selector: #selector(loadPlayers), userInfo: nil, repeats: true)
        }
    }
    
    func showNoPlayers()
    {
        let scene = self.sceneView.scene!
        
        if scene.childNode(withName: "no_players_label_1") == nil
        {
            
            let noPlayers = SKLabelNode(text: "No one is meditating.")
            noPlayers.horizontalAlignmentMode = .center
            noPlayers.numberOfLines = 3
            let fontLabel = UIFont.zendo(font: .antennaRegular, size: 14)
            noPlayers.color = .white
            noPlayers.fontName = fontLabel.fontName
            noPlayers.fontSize = 18
            noPlayers.zPosition = 3.0
            noPlayers.position = CGPoint(x: scene.frame.midX , y: scene.frame.midY)
            noPlayers.name = "no_players_label_1"
            
            scene.addChild(noPlayers)
        }
        
        if scene.childNode(withName: "no_players_label_2") == nil
        {
            let startSession = SKLabelNode(text: "Maybe start a session on your watch?")
            startSession.horizontalAlignmentMode = .center
            startSession.numberOfLines = 3
            let fontLabel = UIFont.zendo(font: .antennaRegular, size: 14)
            startSession.color = .white
            startSession.fontName = fontLabel.fontName
            startSession.fontSize = 18
            startSession.zPosition = 3.0
            startSession.position = CGPoint(x: scene.frame.midX , y: scene.frame.midY - 50)
            startSession.name = "no_players_label_2"
    
            scene.addChild(startSession)
        }
    }
    
    func hideNoPlayer()
    {
        let scene = self.sceneView.scene!
        
        if let noPlayerLabel1 = scene.childNode(withName: "no_players_label_1")
        {
            noPlayerLabel1.removeFromParent()
        }
        
        if let noPlayerLabel2 = scene.childNode(withName: "no_players_label_2")
        {
            noPlayerLabel2.removeFromParent()
        }
    }
    
    func getContent(contentURL: URL, completion: @escaping (AVPlayerItem) -> Void)
    {
        var playerItem: AVPlayerItem?
        
        storage?.async.entry(forKey: contentURL.absoluteString, completion:
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
                
                playerItem = AVPlayerItem(url: contentURL)
                
            }
            
            completion(playerItem!)
            
        })
        
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
                } else
                {
                    if let url = streamUrl
                    {
                        playerItem = AVPlayerItem(url: url)
                    }
                    else
                    {
                        playerItem = AVPlayerItem(url: downloadUrl!)
                    }
                }
                //todo: add invalid to handle a crash
            case .error(let error):
                
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
    
    
    func getIntroScene() -> SKScene
    {
        let scene = SKScene(size: (sceneView.frame.size))
        scene.scaleMode = .resizeFill
        
        self.getContent(contentURL: URL(string: story.introURL!)!)
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
        }
        
        return scene
    }
    
    func getMainScene() -> SKScene
    {
        let scene = SKScene(size: (sceneView.frame.size))
        scene.scaleMode = .resizeFill
        
        sceneView.allowsTransparency = true
        
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
        
        return scene
    }
    
    func setBackground()
    {
        if let story = story, let thumbnailUrl = story.thumbnailUrl, let url = URL(string: thumbnailUrl) {
            UIImage.setImage(from: url) { image in
                DispatchQueue.main.async {
                    self.sceneView.addBackground(image: image, isLayer: false, isReplase: false)
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
    
}


class PlayerNodeOld : SKSpriteNode
{
    var level: Int = 0
    var isMeditating : Bool = false
    let level0Emitter = SKEmitterNode(fileNamed: "Level0Emitter")!
    let level1Emitter = SKEmitterNode(fileNamed: "Level1Emitter")!
    let level2Emitter = SKEmitterNode(fileNamed: "Level2Emitter")!
    let level3Ring = SKShapeNode(circleOfRadius: CGFloat(30.0))
    let level4Planet = SKSpriteNode(imageNamed: "planet")
    let level5Emitter = SKEmitterNode(fileNamed: "Level5Emitter")!
    
    init()
    {
        let texture = SKTexture(imageNamed: "player1")
        super.init(texture: texture, color: .clear, size: texture.size())
        
        level0Emitter.targetNode = self
        level0Emitter.particleZPosition = 4.0
        
        level1Emitter.targetNode = self
        level1Emitter.particleZPosition = 5.0
        
        level2Emitter.targetNode = self
        level2Emitter.particleZPosition = 4.0
        
        level3Ring.strokeColor = SKColor.zenWhite
        level3Ring.position = CGPoint(x: self.frame.midX, y: self.frame.midX)
        
        level3Ring.fillColor = .clear
        level3Ring.zPosition = 6.0
        level3Ring.lineWidth = CGFloat(0.01)
        
        level4Planet.zPosition = 7.0
        level4Planet.color = .blue
        
        level5Emitter.targetNode = self
        level5Emitter.particleZPosition = 8.0
        
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
    }
    
    func updateProgress(progress: String)
    {
        let typed_progress = progress.components(separatedBy: "/")
        let newIsMeditating = typed_progress.first!.boolValue
        let newLevel = Int(typed_progress.last!)
        
        switch (newLevel)
        {
        case 0:
            if(level0Emitter.parent == nil) {
                self.addChild(level0Emitter)
            }
            if(level1Emitter.parent != nil) {
                level1Emitter.removeFromParent()
            }
            if(level2Emitter.parent != nil) {
                level2Emitter.removeFromParent()
            }
            break
            
        case 1:
            
            if(level0Emitter.parent == nil) {
                self.addChild(level0Emitter)
            }
            
            if(level1Emitter.parent == nil) {
                self.addChild(level1Emitter)
            }
            break
            
        case 2:
            if(level0Emitter.parent == nil) {
                self.addChild(level0Emitter)
            }
            if(level1Emitter.parent == nil) {
                self.addChild(level1Emitter)
            }
            if(level2Emitter.parent == nil) {
                self.addChild(level2Emitter)
            }
            
            break
        case 3:
            if(level0Emitter.parent == nil) {
                self.addChild(level0Emitter)
            }
            if(level1Emitter.parent == nil) {
                self.addChild(level1Emitter)
            }
            if(level2Emitter.parent == nil) {
                self.addChild(level2Emitter)
            }
            if(level3Ring.parent == nil) {
                self.addChild(level3Ring)
            }
            
            
            break
        case 4:
            if(level0Emitter.parent == nil) {
                self.addChild(level0Emitter)
            }
            if(level1Emitter.parent == nil) {
                self.addChild(level1Emitter)
            }
            if(level2Emitter.parent != nil) {
                level2Emitter.removeFromParent()
            }
            if(level3Ring.parent == nil) {
                self.addChild(level3Ring)
            }
            
            if(self.level4Planet.parent == nil) {
                
                level3Ring.addChild(level4Planet)
                let action = SKAction.repeatForever(SKAction.follow(level3Ring.path!, asOffset: false, orientToPath: true, speed: 15.0))
                level4Planet.run(action)
                
            }
            
            break
        case 5:
            if(level0Emitter.parent == nil) {
                self.addChild(level0Emitter)
            }
            if(level1Emitter.parent == nil) {
                self.addChild(level1Emitter)
            }
            if(level2Emitter.parent != nil) {
                level2Emitter.removeFromParent()
            }
            if(level3Ring.parent == nil) {
                self.addChild(level3Ring)
            }
            if(self.level4Planet.parent == nil) {
                
                level3Ring.addChild(level4Planet)
                let action = SKAction.repeatForever(SKAction.follow(level3Ring.path!, asOffset: false, orientToPath: true, speed: 15.0))
                level4Planet.run(action)
                
            }
            if(level5Emitter.parent == nil) {
                level4Planet.addChild(level5Emitter)
            }
            break
        default:
            break
        }
        
        self.level = newLevel!
        self.isMeditating = newIsMeditating
    }
}
    
    class PlayerNode : SKSpriteNode
    {
        var level: Int = 0
        var isMeditating : Bool = false
        
        let fieldEmitter = SKEmitterNode(fileNamed: "Level0Emitter")!
        let starEmitter = SKEmitterNode(fileNamed: "Level1Emitter")!
        let ring1 = SKShapeNode(circleOfRadius: CGFloat(20.0))
        let ring2 = SKShapeNode(circleOfRadius: CGFloat(40.0))
        let ring3 = SKShapeNode(circleOfRadius: CGFloat(60.0))
        let planet1 = SKSpriteNode(imageNamed: "planet")
        let planet2 = SKSpriteNode(imageNamed: "planet")
        let planet3 = SKSpriteNode(imageNamed: "planet")
        let heartEmitter = SKEmitterNode(fileNamed: "Level5Emitter")!

        init()
        {
            let texture = SKTexture(imageNamed: "player1")
            super.init(texture: texture, color: .clear, size: texture.size())
            
            fieldEmitter.targetNode = self
            fieldEmitter.particleZPosition = 4.0
            
            starEmitter.targetNode = self
            starEmitter.particleZPosition = 5.0
            
            ring1.strokeColor = SKColor.zenWhite
            ring1.position = CGPoint(x: self.frame.midX, y: self.frame.midX)
            ring1.fillColor = .clear
            ring1.zPosition = 6.0
            ring1.lineWidth = CGFloat(0.01)
            
            ring2.strokeColor = SKColor.zenWhite
            ring2.position = CGPoint(x: self.frame.midX, y: self.frame.midX)
            ring2.fillColor = .clear
            ring2.zPosition = 6.0
            ring2.lineWidth = CGFloat(0.01)
            
            ring3.strokeColor = SKColor.zenWhite
            ring3.position = CGPoint(x: self.frame.midX, y: self.frame.midX)
            ring3.fillColor = .clear
            ring3.zPosition = 6.0
            ring3.lineWidth = CGFloat(0.01)
                        
            heartEmitter.targetNode = self
            heartEmitter.particleZPosition = 8.0
            
        }
        
        required init?(coder: NSCoder)
        {
            super.init(coder: coder)
        }
        
        func updateProgress(progress: String)
        {
            let typed_progress = progress.components(separatedBy: "/")
            let newIsMeditating = typed_progress.first!.boolValue
            let newLevel = Int(typed_progress.last!)
            
            switch (newLevel)
            {
                case 0:
                    if(fieldEmitter.parent == nil) {
                        self.addChild(fieldEmitter)
                    }
                    if(starEmitter.parent != nil) {
                        starEmitter.removeFromParent()
                    }
                    if(ring1.parent != nil) {
                        ring1.removeFromParent()
                    }
                    if(ring2.parent != nil) {
                        ring2.removeFromParent()
                    }
                    if(ring3.parent != nil) {
                        ring3.removeFromParent()
                    }
                    break
                
                case 1:
                    
                    if(fieldEmitter.parent == nil) {
                        self.addChild(fieldEmitter)
                    }
                    
                    if(starEmitter.parent == nil) {
                        self.addChild(starEmitter)
                    }
                    break
                
            case 2:
                    if(fieldEmitter.parent == nil) {
                        self.addChild(fieldEmitter)
                    }
                    if(starEmitter.parent == nil) {
                        self.addChild(starEmitter)
                    }
                    if(ring1.parent == nil) {
                        self.addChild(ring1)
                        ring1.addChild(planet1)
                        let action = SKAction.repeatForever(SKAction.follow(ring1.path!, asOffset: false, orientToPath: true, speed: 15.0))
                        planet1.run(action)
                    }
                
                break
            case 3:
                if(fieldEmitter.parent == nil) {
                    self.addChild(fieldEmitter)
                }
                if(starEmitter.parent == nil) {
                    self.addChild(starEmitter)
                }
                if(ring1.parent == nil) {
                    self.addChild(ring1)
                    ring1.addChild(planet1)
                    let action = SKAction.repeatForever(SKAction.follow(ring1.path!, asOffset: false, orientToPath: true, speed: 15.0))
                    planet1.run(action)
                }
                if(ring2.parent == nil) {
                    self.addChild(ring2)
                    ring1.addChild(planet2)
                    let action = SKAction.repeatForever(SKAction.follow(ring2.path!, asOffset: false, orientToPath: true, speed: 15.0))
                    planet2.run(action)
                }
                
                
                break
            case 4:
                if(fieldEmitter.parent == nil) {
                    self.addChild(fieldEmitter)
                }
                if(starEmitter.parent == nil) {
                    self.addChild(starEmitter)
                }
                if(ring1.parent == nil) {
                    self.addChild(ring1)
                    ring1.addChild(planet1)
                    let action = SKAction.repeatForever(SKAction.follow(ring1.path!, asOffset: false, orientToPath: true, speed: 15.0))
                    planet1.run(action)
                }
                if(ring2.parent == nil) {
                    self.addChild(ring2)
                    ring1.addChild(planet2)
                    let action = SKAction.repeatForever(SKAction.follow(ring2.path!, asOffset: false, orientToPath: true, speed: 15.0))
                    planet2.run(action)
                }
                
                if(ring3.parent == nil) {
                    self.addChild(ring3)
                    ring3.addChild(planet3)
                    let action = SKAction.repeatForever(SKAction.follow(ring3.path!, asOffset: false, orientToPath: true, speed: 15.0))
                    planet3.run(action)
                }
                
                break
            case 5:
                if(fieldEmitter.parent == nil) {
                    self.addChild(fieldEmitter)
                }
                if(starEmitter.parent == nil) {
                    self.addChild(starEmitter)
                }
                if(ring1.parent == nil) {
                    self.addChild(ring1)
                    ring1.addChild(planet1)
                    let action = SKAction.repeatForever(SKAction.follow(ring1.path!, asOffset: false, orientToPath: true, speed: 15.0))
                    planet1.run(action)
                }
                if(ring2.parent == nil) {
                    self.addChild(ring2)
                    ring1.addChild(planet2)
                    let action = SKAction.repeatForever(SKAction.follow(ring2.path!, asOffset: false, orientToPath: true, speed: 15.0))
                    planet2.run(action)
                }
                
                if(ring3.parent == nil) {
                    self.addChild(ring3)
                    ring3.addChild(planet3)
                    let action = SKAction.repeatForever(SKAction.follow(ring3.path!, asOffset: false, orientToPath: true, speed: 15.0))
                    planet3.run(action)
                }
                if(heartEmitter.parent == nil) {
                    planet3.addChild(heartEmitter)
                }
                break
            default:
                break
            }
            
            self.level = newLevel!
            self.isMeditating = newIsMeditating
        }

    }

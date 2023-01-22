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
import SwiftyJSON
import Vision

class GameController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate
{
    //#todo(debt): If we moved to SwiftUI can we get rid of some of this?
    var idHero = "" //not too sure what this does but it is store for the one of the dependencies that we have
    
    //#todo(debt): //not too sure why this isn't just in the HUDView?
    var chartHR = [String: Int]()

    //#todo(debt): put all of this into a game control
    let player = SKSpriteNode(imageNamed: "player1")
    var ring: Int = 0
    var rings = [SKShapeNode]()
    
    //todo(debt): all of this private stuff should be in a shared place?
    //should be common to all Stories?
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoFileOutput = AVCaptureMovieFileOutput()
    private var drawings: [CAShapeLayer] = []
    private let diskConfig = DiskConfig(name: "DiskCache")
    private let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    private lazy var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()
    
    var zensor: Zensor?
    var story: Story!
        
    //todo(7.0): enable + move into story
    var enableLivestream: Bool = false
    var enableFaceDetection: Bool = false

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
    
    //#todo(8.0): turn this into a control
    @IBOutlet weak var outroMessageLabel: UILabel!
    {
        didSet {
            
            outroMessageLabel.isHidden = true
            outroMessageLabel.text = "if you are reading this, it is already too late?"
        }
    }
    
    @objc func setOutroToggle()
    {
        self.outroMessageLabel.isHidden = !self.outroMessageLabel.isHidden
    }
    
    @objc func toggleFullscreen()
    {
        self.toggleStatsView()
        self.toggleProgressView()
        
    }
    
    @IBOutlet weak var progressView: ProgressView! {
        didSet {
            
            progressView.isHidden = !self.story.enableProgress
            progressView.alpha = 1.0
            
            self.progressView.update(minutes: "--", progress: "--/--",
                                     cause: self.story.causePayID ?? "", sponsor: self.story.sponsorPayID ?? "$sponsor",
                                     creator: self.story.creatorPayID ?? "$creator", meditator:"---")
        }
    }
    
    @objc func toggleProgressView()
    {
        if(self.story.enableProgress)
        {
            self.progressView.isHidden = !self.progressView.isHidden
        }
    }
    
    @IBOutlet weak var statsView: ArenaView! {
        didSet {
            
            statsView.isHidden = true
            statsView.alpha = 1.0
            statsView.hrv.text = "--"
            statsView.time.text = "--"
            
        }
    }
    
    @objc func toggleStatsView()
    {
        if(self.story.enableStats)
        {
            self.statsView.isHidden = !self.statsView.isHidden
        }
    }
    
    @IBOutlet weak var connectButton: UIButton!
    {
        didSet
        {
            self.connectButton.addTarget(self, action: #selector(connectZensor), for: .primaryActionTriggered)
            
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
        
        self.previewLayer.frame = self.view.frame
        self.sceneView.frame = self.view.frame
        
        self.previewLayer.opacity = Float(self.story.cameraOpacity ?? "1.0") ?? 1.0
        self.sceneView.alpha = CGFloat(Float(self.story.backgroundOpacity ?? "1.0") ?? 1.0)
        
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.zPosition = -1
        self.sceneView.layer.zPosition = 0
        self.statsView.layer.zPosition = 2
        self.outroMessageLabel.layer.zPosition = 2
        self.progressView.layer.zPosition = 2
        
    }
    
    static func loadFromStoryboard() -> GameController
    {
        let controller = UIStoryboard(name: "GameController", bundle: nil).instantiateViewController(withIdentifier: "GameController") as! GameController
        
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
        
        setupWatchNotifications()
        
        startSession()
        
    }
    
    func setupCamera()
    {
        do {
            
            guard let device = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                    mediaType: .video,
                    position: .front).devices.first else { fatalError("in simulation")
            }
            
            let cameraInput = try AVCaptureDeviceInput(device: device)
            self.captureSession.addInput(cameraInput)
            
            let audio = AVCaptureDevice.default(for: .audio)
            let audioInput = try AVCaptureDeviceInput(device: audio!)
            self.captureSession.addInput(audioInput)
            
            self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
            
            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
            
            self.captureSession.addOutput(self.videoDataOutput)
        
            guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
              connection.isVideoOrientationSupported else { return }
        
            connection.videoOrientation = .portrait
        
            self.captureSession.addOutput(videoFileOutput)
            
        }
        catch
        {
            print(error)
            self.story.enableRecord = false
        }
    }
    
    func setupPhoneAV() {
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        modalPresentationCapturesStatusBarAppearance = true
        
        do {
            
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }
    
    func setupLivestream()
    {
        
        //rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
        // print(error)
        // }
        
        //rtmpStream.attachCamera(DeviceUtil.device(withPosition: .front)) { error in
        // print(error)
        //}
        
        
        //rtmpConnection.connect("rtmp://live-sjc05.twitch.tv/app/live_526664141_tw0025TCdNZBqEkTxmhAllcIQVlvfQ")
        //rtmpStream.publish("streamName")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        
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
    
    //#todo(6.0): need to wire up the BLE Zensor too.
    @objc func connectZensor()
    {
        checkHealthKit(isShow: true)
        
        let startingSessions = StartingSessionViewController()
        
        startingSessions.modalPresentationStyle = .overFullScreen
        
        startingSessions.modalTransitionStyle = .crossDissolve
        
        self.present(startingSessions, animated: true)
        
    }
    
    @objc func startSession() {
        
        if(Settings.isZensorConnected)
        {
            Mixpanel.mainInstance().time(event: "phone_game_start_session")
            
            DispatchQueue.main.async
            {
                if(self.story.enableRecord) {
                    
                    self.setupCamera()
                    
                    self.setupLivestream()
                }
                
                self.setupPhoneAV()
                
                let main = self.getMainScene()
                
                self.sceneView.presentScene(nil) //don't ask, just invoke
                
                self.sceneView.presentScene(main)
                
                let toggleFullscreenGesture = UITapGestureRecognizer(
                    target: self,
                    action: #selector(self.toggleFullscreen)
                )
                
                toggleFullscreenGesture.numberOfTapsRequired = 2
                
                self.sceneView.addGestureRecognizer(toggleFullscreenGesture)
                
                UIView.animate(withDuration: 0.5)
                {
                    self.statsView.isHidden = false
                    self.progressView.isHidden = !self.story.enableProgress
                    self.sceneView.isHidden = false
                }
                //todo(bug): this has to be done outside of the
                //animate for some reason, maybe a beta os issue
                self.connectButton.isHidden = true
                self.outroMessageLabel.isHidden = true
                
                if(self.story.enableRecord)
                {
                    self.captureSession.startRunning()
                        
                    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                    
                    let fileUrl = paths[0].appendingPathComponent("meditation.mov")
                    
                    try? FileManager.default.removeItem(at: fileUrl)
                        
                    self.videoFileOutput.startRecording(to: fileUrl, recordingDelegate: self)
                    
                }
            }
            
        } else {
            
            DispatchQueue.main.async
            {
                self.sceneView.presentScene(self.getIntroScene())
            }
        }
        
    }
    
    
    @objc func endSession() {
        
        Mixpanel.mainInstance().track(event: "phone_lab_watch_connected",
                                      properties: ["name": self.story.title])
        
        
        if(Settings.isZensorConnected) {
            
            if(self.story.enableRecord)
            {
                self.captureSession.stopRunning()
                self.videoFileOutput.stopRecording()
            }
            
            if(self.story.enableBoard)
            {
                self.player.removeAllActions()
                self.player.removeFromParent()
                self.rings.forEach { (ring) in
                    ring.removeFromParent()
                }
            }
            
            ZBFHealthKit.getWorkouts(limit: 1) {
                
                workouts in
                
                if (workouts.count > 0 ) {
                    
                    DispatchQueue.main.async
                    {
                        let vc = ZazenController.loadFromStoryboard()
                        
                        vc.workout = workouts[0]
                        
                        self.present(vc, animated: true)
                        
                    }
                }
            }
    
            DispatchQueue.main.async
            {
                UIView.animate(withDuration: 0.5)
                {
                    self.connectButton.isHidden = true
                    self.sceneView.isHidden = false
                    self.progressView.isHidden = !self.story.enableProgress
                    self.statsView.isHidden = false
                    self.outroMessageLabel.isHidden = false
                    self.outroMessageLabel.text = self.story.outroMessage ?? "Be well."
                }
            }
        }
    }
    
    @objc func progress(notification: NSNotification) {
        
        if let progress = notification.object as? String {
            
            if let zensor  = self.zensor
            {
                zensor.update(progress: progress.description.lowercased())
            }
          
            DispatchQueue.main.async
            {
                if self.story.enableBoard
                {
                    self.updateGame(notification: notification)
                }
                
            }
        }
    }
    
    func updateGame(notification: NSNotification)
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
                    
                    if let shell = self.sceneView.scene!.childNode(withName: "//0")! as? SKShapeNode {
                        
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
                        
                    if let shell = self.sceneView.scene!.childNode(withName: "//" + self.ring.description)! as? SKShapeNode
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
            let donatedString = sample["donated"] as? String ?? "--"
            let progressString = sample["progress"] as? String ?? "--/--"
            let appleID = sample["appleID"] as? String ?? "---"
            let creatorPayID = self.story.creatorPayID ?? "--"
            let causePayID = self.story.causePayID ?? "--"
            let sponsorPayID = self.story.sponsorPayID ?? "--"
            
            self.chartHR[String(Date().timeIntervalSince1970)] = int_hr
            
            let chartHR = self.chartHR.sorted(by: <)
            
            DispatchQueue.main.async
            {
                self.statsView.hrv.text = text_hrv
                self.statsView.time.text = text_hr
                self.statsView.setChart(chartHR)
                
                self.progressView.update(minutes: donatedString, progress: progressString, cause: causePayID, sponsor: sponsorPayID, creator: creatorPayID, meditator: appleID)
                
            }
            
            if let zensor  = self.zensor
            {
                zensor.update(hr: Float(double_hr) )
            }
            else
            {
                self.zensor = Zensor(id: UUID() , name: Settings.email ?? "Apple Watch", hr: Float(double_hr) , batt: 100)
            }
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
        
        //let scene = SKScene(size: (UIScreen.main.bounds.size))
        
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
        
        if(self.story.enableBoard!)
        {
            self.player.removeAllActions()
            self.player.removeFromParent()
            
            self.addShell(scene, 30, "2")
            self.addShell(scene, 90, "1")
            self.addShell(scene, 150, "0")
            
            if let shell = scene.childNode(withName: "//0")! as? SKShapeNode
            {
                shell.addChild(self.player)
                
                self.player.zPosition = 3.0
                
                let action = SKAction.repeatForever(SKAction.follow(shell.path!, asOffset: false, orientToPath: true, speed: 15.0))
                
                self.player.run(action)
               
            }
            
        }
        
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
        
        pathNode.isHidden = false
        
        pathNode.lineWidth = CGFloat(0.01)
        
        parent.addChild(pathNode)
        
        rings.append(pathNode)
    }
    
    func setBackground() {
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
    
    //todo(debt): this is bunch of code to track the donator in the camera frame.
    @objc func faceDetectionEnabled()
    {
        self.clearDrawings()
        self.enableFaceDetection = !self.enableFaceDetection
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        
        self.detectFace(in: frame)
        
    }
    
    private func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation] {
                    if(self.enableFaceDetection) {
                        self.handleFaceDetectionResults(results)
                    }
                } else {
                    self.clearDrawings()
                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
    private func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation]) {
        
        self.clearDrawings()
        let facesBoundingBoxes: [CAShapeLayer] = observedFaces.flatMap({ (observedFace: VNFaceObservation) -> [CAShapeLayer] in
            let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
            let faceBoundingBoxShape = CAShapeLayer()
            faceBoundingBoxShape.path = faceBoundingBoxPath
            faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
            faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
            var newDrawings = [CAShapeLayer]()
            newDrawings.append(faceBoundingBoxShape)
            if let landmarks = observedFace.landmarks {
                newDrawings = newDrawings + self.drawFaceFeatures(landmarks, screenBoundingBox: faceBoundingBoxOnScreen)
            }
            return newDrawings
        })
        facesBoundingBoxes.forEach({ faceBoundingBox in self.view.layer.addSublayer(faceBoundingBox) })
        self.drawings = facesBoundingBoxes
    }
    
    private func clearDrawings() {
        self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
    }
    
    private func drawFaceFeatures(_ landmarks: VNFaceLandmarks2D, screenBoundingBox: CGRect) -> [CAShapeLayer] {
        var faceFeaturesDrawings: [CAShapeLayer] = []
        if let leftEye = landmarks.leftEye {
            let eyeDrawing = self.drawEye(leftEye, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        if let rightEye = landmarks.rightEye {
            let eyeDrawing = self.drawEye(rightEye, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        // draw other face features here
        
        if let innerLips = landmarks.innerLips {
            let lipsDrawing = self.drawEye(innerLips, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(lipsDrawing)
        }
        if let outerLips = landmarks.outerLips {
            let lipsDrawing = self.drawEye(outerLips, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(lipsDrawing)
        }
        return faceFeaturesDrawings
    }
    
    private func drawEye(_ eye: VNFaceLandmarkRegion2D, screenBoundingBox: CGRect) -> CAShapeLayer {
        let eyePath = CGMutablePath()
        let eyePathPoints = eye.normalizedPoints
            .map({ eyePoint in
                CGPoint(
                    x: eyePoint.y * screenBoundingBox.height + screenBoundingBox.origin.x,
                    y: eyePoint.x * screenBoundingBox.width + screenBoundingBox.origin.y)
            })
        eyePath.addLines(between: eyePathPoints)
        eyePath.closeSubpath()
        let eyeDrawing = CAShapeLayer()
        eyeDrawing.path = eyePath
        eyeDrawing.fillColor = UIColor.clear.cgColor
        eyeDrawing.strokeColor = UIColor.green.cgColor
        
        return eyeDrawing
    }
}

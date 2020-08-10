//
//  LabController.swift
//  Zendo
//
//  Created by Douglas Purdy on 5/8/20.
//  Copyright © 2020 zenbf. All rights reserved.
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
import Vision
import HaishinKit

class LabController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate
{
    var appleWatch : Zensor?
    var story: Story!
    var idHero = ""
    var panGR: UIPanGestureRecognizer!
    var chartHR = [String: Int]()
    let player = SKSpriteNode(imageNamed: "player1")
    var ring: Int = 0
    var showLevels : Bool = false
    var showGroups : Bool = false
    var rings = [SKShapeNode]()
    var scene: SKScene!
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var drawings: [CAShapeLayer] = []
    
    private let rtmpConnection = RTMPConnection()
    private lazy var rtmpStream = RTMPStream(connection: self.rtmpConnection)
    
    @IBOutlet weak var sceneView: SKView!
    {
        
        didSet {
            sceneView.hero.id = idHero
        }
    }
    
    @IBOutlet weak var progressView: ProgressView! {
            didSet {

                progressView.isHidden = true
                progressView.alpha = 1.0
                self.progressView.hrv.text = "--"
                self.progressView.time.text = "--"
                
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

    
    static func loadFromStoryboard() -> LabController
    {
        let controller = UIStoryboard(name: "LabController", bundle: nil).instantiateViewController(withIdentifier: "LabController") as! LabController
        
        return controller
    }
    
   
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
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
    
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front).devices.first else {
                fatalError("No back camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func showCameraFeed() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.zPosition = -1
        self.previewLayer.frame = self.view.frame
    }
    
    private func getCameraFrames() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    
    private func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionResults(results)
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
    

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        Mixpanel.mainInstance().time(event: "phone_lab")
        
        setupWatchNotifications()
        
        do {
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        
        modalPresentationCapturesStatusBarAppearance = true
        
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
        
        sceneView.addGestureRecognizer(panGR)
        sceneView.backgroundColor = .clear
        
        self.scene = self.setupScene()
        
        
        setupConnectButton()
        
        self.startSession()
        
        self.addCameraInput()
        self.showCameraFeed()
        self.getCameraFrames()
        self.captureSession.startRunning()
        
        rtmpStream.attachAudio(AVCaptureDevice.default(for: AVMediaType.audio)) { error in
              // print(error)
          }
          rtmpStream.attachCamera(DeviceUtil.device(withPosition: .front)) { error in
              // print(error)
          }
          
        rtmpConnection.connect("rtmp://live-sjc05.twitch.tv/app/live_526664141_tw0025TCdNZBqEkTxmhAllcIQVlvfQ")
        rtmpStream.publish("streamName")

    }
    
   
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "phone_lab", properties: ["name": story.title])
        
        NotificationCenter.default.removeObserver(self)
                
        UIApplication.shared.isIdleTimerDisabled = false
        
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
            
            DispatchQueue.main.async
            {
                UIView.animate(withDuration: 0.5)
                {
                    self.arenaView.isHidden = false
                    self.progressView.isHidden = false
                    self.connectButton.isHidden = true
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
            UIView.animate(withDuration: 0.5)
            {
                    
                    self.arenaView.isHidden = true
                    self.connectButton.isHidden = false
                    self.progressView.isHidden = true
                    self.arenaView.hrv.text = "--"
                    self.arenaView.time.text = "--"
                    self.arenaView.setChart([])
                }
                
            }
            
        }
    
    @objc func progress(notification: NSNotification)
    {
        if let progress = notification.object as? String
        {
            let lastProgress = progress.description.lowercased().contains("true")
            
            if let watch  = self.appleWatch
            {
                watch.update(progress: progress.description.lowercased())
            }
        }
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
    
    func setupScene() -> SKScene
    {
        sceneView.frame = UIScreen.main.bounds
        sceneView.contentMode = .scaleAspectFill
        
        let scene = SKScene()
        
        sceneView.backgroundColor = .clear
        
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
    
        self.addShell(scene, 30, "2")
        self.addShell(scene, 90, "1")
        self.addShell(scene, 150, "0")
        
        return scene
        
    }
    
    let diskConfig = DiskConfig(name: "DiskCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    
    lazy var storage: Cache.Storage? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()
  
    
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
            
            
            DispatchQueue.main.async
            {
                
                self.progressView.hrv.text = "1" //
                self.progressView.time.text = "1"
            }
            
            if let watch  = self.appleWatch
            {
                watch.update(hr: Float(double_hr) )
            }
            else
            {
                self.appleWatch = Zensor(id: UUID() , name: Settings.email!, hr: Float(double_hr) , batt: 100)
            }
        }
        
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
          //  Hero.shared.apply(modifiers: [.position(currentPos)], to: twitchView)
        default:
            
             Hero.shared.finish()
            
        }

    }
}




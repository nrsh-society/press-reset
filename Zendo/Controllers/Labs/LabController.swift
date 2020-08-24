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
import XpringKit

class LabController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate
{
    //#todo(debt): If we moved to SwiftUI can we get rid of some of this?
    var idHero = "" //not too sure what this does but it is store for the one of the dependencies that we have
    
    //#todo(debt): //not too sure why this isn't just in the HUDView?
    var chartHR = [String: Int]()
    
    //todo(debt): this should be moved to some debug setting thing?
    var enableFaceDetection: Bool = false
    
    //todo(debt): all of this private stuff should be in a shared place?
    //should be common to all Stories?
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoFileOutput = AVCaptureMovieFileOutput()
    private var drawings: [CAShapeLayer] = []
    private let rtmpConnection = RTMPConnection()
    private lazy var rtmpStream = RTMPStream(connection: self.rtmpConnection)
    private let diskConfig = DiskConfig(name: "DiskCache")
    private let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    private lazy var storage: Cache.Storage? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()
    
    var zensor: Zensor?
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
            
            let enableFaceDetectionGesture  = UITapGestureRecognizer(
                target: self,
                action: #selector(faceDetectionEnabled)
              )
            
            enableFaceDetectionGesture.numberOfTapsRequired = 2
            
            sceneView.addGestureRecognizer(enableFaceDetectionGesture)
      
        }
    }
    
    @IBOutlet weak var outroMessageLabel: UILabel!
    {
            didSet {
                outroMessageLabel.isHidden = true
                outroMessageLabel.text = "if you are reading this, it is already too late?"
            }
    }
    
    
    @IBOutlet weak var progressView: ProgressView! {
            didSet {

                progressView.isHidden = true
                progressView.alpha = 1.0
                self.progressView.update(minutes: "--", progress: "--/--",
                                         cause: "--", sponsor: "--",
                                         creator: "--", meditator:"--")
            }
        }
    
    @IBOutlet weak var arenaView: ArenaView! {
        didSet {

            arenaView.isHidden = true
            arenaView.alpha = 1.0
            arenaView.hrv.text = "--"
            arenaView.time.text = "--"
            
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
        
    }
    
    static func loadFromStoryboard() -> LabController
    {
        let controller = UIStoryboard(name: "LabController", bundle: nil).instantiateViewController(withIdentifier: "LabController") as! LabController
        
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
    
        setupPhoneSensors()
        
        setupPhoneAV()
        
        setupLivestream()
    
        setupWatchNotifications()
        
        startSession()
        
    }

    func setupPhoneSensors() {
        
        addCameraIn()
        getCameraOut()
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
        let startingSessions = StartingSessionViewController()
        
        startingSessions.modalPresentationStyle = .overFullScreen
        
        startingSessions.modalTransitionStyle = .crossDissolve
        
        self.present(startingSessions, animated: true)
        
    }
    
    @objc func startSession()
    {

        if(Settings.isZensorConnected)
        {
            Mixpanel.mainInstance().time(event: "phone_lab_watch_connected")
                        
            DispatchQueue.main.async
            {
                self.sceneView.presentScene(self.getMainScene())
                
                UIView.animate(withDuration: 0.5)
                {
                    self.arenaView.isHidden = false
                    self.progressView.isHidden = false
                    self.sceneView.isHidden = false
                }
                //todo(bug): this has to be done outside of the
                //animate for some reason, maybe a beta os issue
                self.connectButton.isHidden = true
                self.outroMessageLabel.isHidden = true
                
                self.captureSession.startRunning()
            }
        } else
        {
            DispatchQueue.main.async
            {
                self.sceneView.presentScene(self.getIntroScene())
            }
        }
     
    }
    
    @objc func endSession() {
        
        
        Mixpanel.mainInstance().track(event: "phone_lab_watch_connected",
                                      properties: ["name": self.story.title])
        
        ZBFHealthKit.getWorkouts(limit: 1) {
         
            workouts in
            
            if (workouts.count > 0 ) {
            
                DispatchQueue.main.async
                {
                    let vc = ZazenController.loadFromStoryboard()
                    
                    vc.workout = (workouts[0] as! HKWorkout)
                
                    self.present(vc, animated: true)
                    
                }
            }
        }
        
        let message = """

        +:nothing to add.
        -:nothing to subtract.
        =:nothing is complete.

        """
        
        DispatchQueue.main.async
        {
            UIView.animate(withDuration: 0.5)
            {
                self.connectButton.isHidden = true
                self.sceneView.isHidden = false
                self.progressView.isHidden = false
                self.arenaView.isHidden = false
                self.outroMessageLabel.isHidden = false
                self.outroMessageLabel.text = self.story.outroMessage ?? message
                
            }
        }
    }
    
    @objc func progress(notification: NSNotification) {
        
        if let progress = notification.object as? String {
        
            if let zensor  = self.zensor
            {
                zensor.update(progress: progress.description.lowercased())
            }
            
            payout()
        }
    }
    
    //todo(bug, blocker): think this is fixed now, but least see.
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
            let creatorPayID = self.story.creatorPayID!
            let causePayID = self.story.causePayID!
            let sponsorPayID = self.story.sponsorPayID!
            
            self.chartHR[String(Date().timeIntervalSince1970)] = int_hr
            
            let chartHR = self.chartHR.sorted(by: <)
       
            DispatchQueue.main.async
            {
                self.arenaView.hrv.text = text_hrv
                self.arenaView.time.text = text_hr
                self.arenaView.setChart(chartHR)
                            
                self.progressView.update(minutes: donatedString, progress: progressString, cause: causePayID, sponsor: sponsorPayID, creator: creatorPayID, meditator: Settings.email ?? "anonymous")
                
            }
            
            if let zensor  = self.zensor
            {
                zensor.update(hr: Float(double_hr) )
            }
            else
            {
                self.zensor = Zensor(id: UUID() , name: Settings.email!, hr: Float(double_hr) , batt: 100)
            }
            
            self.donate()
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
    
    
    func getIntroScene() -> SKScene
    {
        let scene = SKScene(size: (sceneView.frame.size))
        scene.scaleMode = .aspectFill
        
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
        scene.scaleMode = .aspectFill
        
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
            
        return scene
    }
    
    //todo(debt): put all of this stuff in a MoneyKit.swift file.
    func moveXrp(source: Wallet, target: String, drops: UInt64, useMainnet: Bool)
    {
           
        let xpringClient = DefaultXRPClient(grpcURL: "main.xrp.xpring.io:50051", xrplNetwork: XRPLNetwork.main)
           
        let transactionHash = try! xpringClient.send(drops, to: target, from: source)
           
        let status = try! xpringClient.paymentStatus(for: transactionHash)
        
        let success = status == TransactionStatus.succeeded
           
        let retval = (txn: transactionHash.description, status: success.description)
           
        print ("[txn: \(retval.txn)] \r\n")
    
    }
    
    func donate()
    {
        let causePayID = story.causePayID!
        
        let payIDClient = PayIDClient()
        
        let causeXRPLAddress = try! payIDClient.cryptoAddress(for: causePayID, on: "xrpl-mainnet").get()
        
        let tag = UInt32(causeXRPLAddress.tag ?? "0")
        
        let causeXAddress = Utils.encode(classicAddress: causeXRPLAddress.address, tag: tag, isTest: false)!
        
        let amount = UInt64(166666)
        
        let wallet = Wallet(seed: story.sponsorKey!)!
        
        self.moveXrp(source: wallet, target: causeXAddress, drops: amount, useMainnet: true)
          
    }
    
    func payout()
    {
        let creatorPayID = story.creatorPayID!

        let payIDClient = PayIDClient()

        let creatorXRPLAddress = try! payIDClient.cryptoAddress(for: creatorPayID, on: "xrpl-mainnet").get()

        let tag = UInt32(creatorXRPLAddress.tag ?? "0")

        let causeXAddress = Utils.encode(classicAddress: creatorXRPLAddress.address, tag: tag, isTest: false)!

        let amount = UInt64(166666)

        let wallet = Wallet(seed: story.sponsorKey!)!

        self.moveXrp(source: wallet, target: causeXAddress, drops: amount, useMainnet: true)
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
    
    private func addCameraIn() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front).devices.first else {
                fatalError("No back camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    
    private func getCameraOut() {
        
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




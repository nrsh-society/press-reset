//
//  VideoViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 18/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import AVFoundation
import Hero
import Cache
import Mixpanel
import Firebase
import FirebaseDatabase

enum PlayerStatus: Float {
    case pause = 0.0
    case play = 1.0
    
    var image: UIImage? {
        switch self {
        case .pause: return UIImage(named: "icnPause")
        case .play: return UIImage(named: "icnPlay")
        }
    }
}

class VideoViewController: UIViewController {
    
    var panGR: UIPanGestureRecognizer!
    var playerStatus = PlayerStatus.play

    let diskConfig = DiskConfig(name: "DiskCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    
    lazy var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()
    
    
    @IBOutlet weak var pauseView: UIView! {
        didSet {
            pauseView.alpha = 0.0
            pauseView.layoutIfNeeded()
            pauseView.layer.cornerRadius = pauseView.frame.height / 2.0
        }
    }
    @IBOutlet weak var pauseImage: PauseImageView! {
        didSet{
            pauseImage.playerStatus = .pause
        }
    }
    @IBOutlet weak var pauseLabel: UILabel!
    @IBOutlet weak var loadStackView: UIStackView!
    @IBOutlet weak var activity: UIActivityIndicatorView! {
        didSet {
            activity.color = UIColor.zenDarkGreen
        }
    }
    @IBOutlet weak var rightView: UIView! {
        didSet {
            rightView.backgroundColor = .clear
        }
    }
    @IBOutlet weak var leftView: UIView! {
        didSet {
            leftView.backgroundColor = .clear
        }
    }
    @IBOutlet weak var centerView: UIView! {
        didSet {
            centerView.backgroundColor = .clear
        }
    }
    @IBOutlet weak var video: UIView! {
        didSet {
            video.hero.id = idHero
        }
    }
    
    @IBOutlet weak var tickerLabel: UILabel!
    @IBOutlet weak var groupTextView: UITextView!
    
    var idHero = ""
    var current = 0
    var previous: Int?
    
    var playerLayers = [AVPlayerLayer]()
    
    var playerLayerCurrent: AVPlayerLayer {
        return playerLayers[current]
    }
    
    var playerLayerPrevious: AVPlayerLayer? {
        return previous == nil ? nil : playerLayers[previous!]
    }
    
    var playerObserver: Any?
    var story: Story!
    var timer: Timer?
    
    let interval = CMTime(seconds: 0.01, preferredTimescale: 1000)
    let mainQueue = DispatchQueue.main
    
  
    override func didReceiveMemoryWarning()
    {
        try? storage?.removeAll()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Mixpanel.mainInstance().time(event: "phone_story")
        
        let animation: CATransition = CATransition()
        animation.duration = 1.0
        animation.type = kCATransitionFade
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        self.tickerLabel.layer.add(animation, forKey: "changeTextTransition")
       
        do {
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(pauseViewAction))
        pauseView.addGestureRecognizer(gr)
        
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
        video.addGestureRecognizer(panGR)
        
        if let story = story {
            
            if let thumbnailUrl = story.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                UIImage.setImage(from: url) { image in
                    DispatchQueue.main.async {
                        self.video.addBackground(image: image, isLayer: true, isReplase: false)
                    }
                }
            }
            
            for (index, content) in story.content.enumerated() {
                
                if let urlContent = content.stream, let urlStream = URL(string: urlContent), index <= 1 {
                    
                    var urlDownload: URL?
                    
                    if let download = content.download, let url = URL(string: download) {
                        urlDownload = url
                    }
                    
                    let pathExtension = urlStream.pathExtension.lowercased()
                    
                    if pathExtension == "png" || pathExtension == "jpg" || pathExtension == "jpeg"
                    {
                        startImage(urlStream, index: index)
                    }
                    else
                    {
                        play(with: urlStream, urlDownload: urlDownload)
                    {
                            playerLayer in
                            
                                self.playerLayers.append(playerLayer)
                            
                            if index == 0
                            {
                                self.startVideo()
                            }
                        }
                    }
                    
                }
                
                loadStackView.addArrangedSubview(LoadingView())
                
            }
            
        }
        
        
        let grLeft = UITapGestureRecognizer(target: self, action: #selector(tapLeft))
        leftView.addGestureRecognizer(grLeft)
        
        let grRight = UITapGestureRecognizer(target: self, action: #selector(tapRight))
        rightView.addGestureRecognizer(grRight)
        
        let grCenter = UITapGestureRecognizer(target: self, action: #selector(tapCenter))
        centerView.addGestureRecognizer(grCenter)
        
        modalPresentationCapturesStatusBarAppearance = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        Mixpanel.mainInstance().track(event: "phone_story", properties: ["name": story.title])
        
    }
    
    static func loadFromStoryboard() -> VideoViewController {
        return UIStoryboard(name: "Discover", bundle: nil).instantiateViewController(withIdentifier: "VideoViewController") as! VideoViewController
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    func play(with urlStream: URL, urlDownload: URL?, completion: ((AVPlayerLayer)->())? = nil) {
        
        var download = ""
        
        if let url = urlDownload
        {
            download = url.absoluteString
        }
                
        storage?.async.entry(forKey: download, completion: { result in
            let playerItem: AVPlayerItem
            switch result {
            case .error:
                playerItem = AVPlayerItem(url: urlStream)
            case .value(let entry):
                if var path = entry.filePath {
                    if path.first == "/" {
                        path.removeFirst()
                    }
                    
                    let url = URL(fileURLWithPath: path)
                    playerItem = AVPlayerItem(url: url)
                } else {
                    playerItem = AVPlayerItem(url: urlStream)
                }
            }
            
            let player = AVPlayer(playerItem: playerItem)
            
            player.actionAtItemEnd = .none
            player.automaticallyWaitsToMinimizeStalling = true
            player.play()
            player.pause()
            
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = UIScreen.main.bounds
            playerLayer.videoGravity = .resizeAspectFill
            
            completion?(playerLayer)
        })
    }
        
    func startImage(_ url: URL, index: Int? = nil)
    {
    
        activity.stopAnimating()
        
        UIImage.setImage(from: url) { image in
            VideoGenerator.current.shouldOptimiseImageForVideo = true
            VideoGenerator.current.maxVideoLengthInSeconds = 5.0
            VideoGenerator.current.videoDurationInSeconds = 5.0
            
            VideoGenerator.current.generate(withImages: [image], andAudios: [], andType: .single, { (progress) in
            }, success: { (url) in
                self.play(with: url, urlDownload: nil) { playerLayer in
                    self.playerLayers.append(playerLayer)
                    
                    if let i = index, i == 0 {
                        self.startVideo()
                    }
                }
            }, failure: { (error) in
            })
        }

    }
    
    @objc func itemDidPlayToEndTime() {
        tapRight()
    }
    
    func startVideo() {
        
        setBackground()
        
        if let previous = playerLayerPrevious, let observer = self.playerObserver  {
            previous.player?.pause()
            previous.player?.removeTimeObserver(observer)
            previous.removeFromSuperlayer()
            playerObserver = nil
        }
        
        video.layer.insertSublayer(playerLayerCurrent, at: 1)
        playerLayerCurrent.player?.seek(to: kCMTimeZero)
        
        playerLayerCurrent.player?.play()
        
        activity.startAnimating()
        
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        playerObserver = playerLayerCurrent.player?.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) { time in
            
            if let status = PlayerStatus(rawValue: self.playerLayerCurrent.player!.rate), status == .pause && self.playerStatus == .play {
                self.playerLayerCurrent.player?.play()
            }
            
            let duration = self.playerLayerCurrent.player!.currentItem!.duration
            let currentTime = self.playerLayerCurrent.player!.currentTime()
            
            if currentTime.seconds > 0.0 && self.activity.isAnimating {
                self.activity.stopAnimating()
            }
            
            if let view = self.loadStackView.arrangedSubviews[self.current] as? LoadingView {
                let a = currentTime.seconds / duration.seconds
                self.pauseLabel.text = currentTime.seconds.stringZendoTimeWatch
                view.setCurent(a)
            }
            
        }
    }
    
    @objc func pan() {
        let translation = panGR.translation(in: nil)
        let progress = translation.y / view.bounds.height
        switch panGR.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
            Hero.shared.apply(modifiers: [.position(currentPos)], to: video)
        default:
            removeObserver()
            Hero.shared.finish()
            /*
            if progress + panGR.velocity(in: nil).y / view.bounds.height > 0.3 {
             
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
             */
        }
    }
    
    @objc func tapLeft() {
        if let view = loadStackView.arrangedSubviews[current] as? LoadingView {
            view.setStart()
        }
        
        if current > 0 {
            previous = current
            current -= 1
            if let view = loadStackView.arrangedSubviews[current] as? LoadingView {
                view.setStart()
            }
            startVideo()
        }
    }
    
    @objc func tapRight() {
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        if let view = loadStackView.arrangedSubviews[current] as? LoadingView {
            view.setEnd()
        }
        
        if current < story.content.count - 1 {
            previous = current
            current += 1
            startVideo()
            
            let isIndexValid = playerLayers.indices.contains(current + 1)
            
            if !isIndexValid && (current + 1) <= story.content.count - 1,
                let urlContent = story.content[current + 1].stream,
                let urlStream = URL(string: urlContent) {
                
                var urlDownload: URL?
                
                if let download = story.content[current + 1].download, let url = URL(string: download) {
                    urlDownload = url
                }
                
                let pathExtension = urlStream.pathExtension.lowercased()
                
                if pathExtension == "png" || pathExtension == "jpg" || pathExtension == "jpeg"
                {
                    startImage(urlStream)
                
                }
                else
                {
                    play(with: urlStream, urlDownload: urlDownload)
                    {
                        playerLayer in
                        
                        self.playerLayers.append(playerLayer)
                    }
                }
                
            }
            
        } else if current == story.content.count - 1 {
            dismissVideo()
        }
        
    }
    
    func setBackground() {        
        if let story = story, let thumbnailUrl = story.content[current].thumbnailUrl, let url = URL(string: thumbnailUrl) {
            UIImage.setImage(from: url) { image in
                DispatchQueue.main.async {
                    self.video.addBackground(image: image, isLayer: true, isReplase: true)
                }
            }
        }
    }
    
    @objc func tapCenter() {
        if let player = playerLayerCurrent.player, let status = PlayerStatus(rawValue: player.rate) {
            
            switch status {
            case .play: pauseImage.playerStatus = .pause
            case .pause: pauseImage.playerStatus = .play
            }
            
            if pauseView.isHidden {
                self.pauseView.isHidden = false
                UIView.animate(withDuration: 0.3) {
                    self.pauseView.alpha = 1.0
                }
            }
            
            
            
            //            else {
            //                UIView.animate(withDuration: 0.3, animations: {
            //                    self.pauseView.alpha = 0.0
            //                }, completion: { (bool) in
            //                    self.pauseView.isHidden = true
            //                })
            //            }
            
            timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (timer) in
                if status == .play {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.pauseView.alpha = 0.0
                    }, completion: { (bool) in
                        self.pauseView.isHidden = true
                    })
                }
            })
            
        }
        
    }
    
    @objc func pauseViewAction() {
        if let player = playerLayerCurrent.player, let status = PlayerStatus(rawValue: player.rate) {
            switch status {
            case .pause:
                player.play()

                leftView.isHidden = false
                rightView.isHidden = false

                playerStatus = .play
                pauseImage.playerStatus = .pause
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.pauseView.alpha = 0.0
                }, completion: { (bool) in
                    self.pauseView.isHidden = true
                })
            case .play:
                player.pause()

                playerStatus = .pause
                pauseImage.playerStatus = .play
                
                leftView.isHidden = true
                rightView.isHidden = true

                timer?.invalidate()
            }
        }
    }
    
    @objc func dismissVideo()
    {
        removeObserver()
    
        dismiss(animated: true)
    }
    
    func removeObserver() {
        if let observer = self.playerObserver {
            playerLayerCurrent.player?.pause()
            playerLayerCurrent.player?.removeTimeObserver(observer)
            playerObserver = nil
        }
    }
    
}


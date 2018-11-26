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
    
    let diskConfig = DiskConfig(name: "DiskCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    
    lazy var storage: Cache.Storage? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()
    
    @IBOutlet weak var pauseView: UIView! {
        didSet {
            pauseView.alpha = 0.0
            pauseView.layoutIfNeeded()
            pauseView.layer.cornerRadius = pauseView.frame.height / 2.0
        }
    }
    @IBOutlet weak var pauseImage: UIImageView! {
        didSet{
            pauseImage.image = PlayerStatus.pause.image
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
    
    var idHero = ""
    var curent = 0
    var previous: Int?
    
    var playerLayers = [AVPlayerLayer]()
    
    var playerLayerCurrent: AVPlayerLayer {
        return playerLayers[curent]
    }
    
    var playerLayerPrevious: AVPlayerLayer? {
        return previous == nil ? nil : playerLayers[previous!]
    }
    
    var playerObserver: Any?
    var story: Story!
    var timer: Timer?
    
    let interval = CMTime(seconds: 0.01, preferredTimescale: 1000)
    let mainQueue = DispatchQueue.main
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(pauseViewAction))
        pauseView.addGestureRecognizer(gr)
        
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
        video.addGestureRecognizer(panGR)
        
        if let story = story {
            
            if  let thumbnailUrl = story.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                UIImage.setImage(from: url) { image in
                    DispatchQueue.main.async {
                        self.video.addBackground(image: image)
                    }
                }
            }
            
            for (index, content) in story.content.enumerated() {
                
                if let urlContent = content.stream, let url = URL(string: urlContent), index <= 1 {
                    
                    play(with: url) { player in
                        let playerLayer = AVPlayerLayer(player: player)
                        playerLayer.frame = UIScreen.main.bounds
                        playerLayer.videoGravity = .resizeAspectFill
                        
                        self.playerLayers.append(playerLayer)
                        
                        if index == 0 {
                            self.startVideo()
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
    
    static func loadFromStoryboard() -> VideoViewController {
        return UIStoryboard(name: "Discover", bundle: nil).instantiateViewController(withIdentifier: "VideoViewController") as! VideoViewController
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    func play(with url: URL, completion: ((AVPlayer)->())? = nil) {
//        try? storage?.removeAll()
        storage?.async.entry(forKey: url.absoluteString, completion: { result in
            let playerItem: AVPlayerItem
            switch result {
            case .error:
                playerItem = AVPlayerItem(url: url)
            case .value(let entry):
                
                if let path = entry.filePath {
                    
                    let configuration = URLSessionConfiguration.background(withIdentifier: "downloadIdentifier")
                    let downloadSession = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
                    let url = URL(string:path)
                    let asset = AVURLAsset(url: url!)
                    
                    let downloadTask = downloadSession.makeAssetDownloadTask(asset: asset, assetTitle: "downloadedAudio", assetArtworkData: nil, options: nil)
                    downloadTask?.resume()
                    
                    print((downloadTask?.urlAsset)!)
                    
                    playerItem = AVPlayerItem(asset: (downloadTask?.urlAsset)!)
                    
//                    let filepath = URL(fileURLWithPath: path)
//                    playerItem = AVPlayerItem(url: filepath)
                } else {
                    playerItem = AVPlayerItem(url: url)
                }
                
            }
            
            let player = AVPlayer(playerItem: playerItem)
            player.actionAtItemEnd = .none
            player.automaticallyWaitsToMinimizeStalling = false
            player.play()
            player.pause()
            
            completion?(player)
        })
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
        
        playerObserver = playerLayerCurrent.player?.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) { time in
            
            let duration = self.playerLayerCurrent.player!.currentItem!.duration
            let limit = CMTime(seconds: 1.0, preferredTimescale: 1000)
            let maxTime = duration - limit
            
            let currentTime = self.playerLayerCurrent.player!.currentTime()
            
            if currentTime.seconds > 0.0 && self.activity.isAnimating {
                self.activity.stopAnimating()
            }
            
            if currentTime >= maxTime {
                
               
                
                if let player = self.playerLayerCurrent.player!.currentItem {
                    
                    let url: URL? = (player.asset as? AVURLAsset)?.url
                    
                    URLSession.shared.dataTask(with: url!) { data, response, error -> Void in
                        
                        if let data = data, error == nil {
                            do {
                                self.storage?.async.setObject(data, forKey: url!.absoluteString, completion: { _ in })
                            } catch {
                                
                            }
                        }
                        
                        
                        
                        }.resume()
//
//                    guard let filename = url?.absoluteString else {
//                        return
//                    }
//
//                    let documentsDirectory = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last!
//
//                    let outputURL = documentsDirectory.appendingPathComponent(filename)
//
//                    let exporter = AVAssetExportSession(asset: player.asset, presetName: AVAssetExportPresetHighestQuality)
//
//                    exporter?.outputURL = outputURL
//                    exporter?.outputFileType = AVFileType.mov
//
//                    exporter?.exportAsynchronously(completionHandler: {
//
//                        print(exporter?.status.rawValue)
//                        print(exporter?.error)
//
//                        if let video = try? Data(contentsOf: outputURL) {
//                            self.storage?.async.setObject(video, forKey: outputURL.absoluteString, completion: { _ in })
//                        }
//
//                    })
                }
                
                self.tapRight()
                return
            } else {
                if let view = self.loadStackView.arrangedSubviews[self.curent] as? LoadingView {
                    let a = currentTime.seconds / duration.seconds
                    self.pauseLabel.text = currentTime.seconds.stringZendoTimeWatch
                    view.setCurent(a)
                }
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
            if progress + panGR.velocity(in: nil).y / view.bounds.height > 0.3 {
                removeObserver()
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }
    
    @objc func tapLeft() {
        if let view = loadStackView.arrangedSubviews[curent] as? LoadingView {
            view.setStart()
        }
        
        if curent > 0 {
            previous = curent
            curent -= 1
            if let view = loadStackView.arrangedSubviews[curent] as? LoadingView {
                view.setStart()
            }
            startVideo()
        }
    }
    
    @objc func tapRight() {

        if let view = loadStackView.arrangedSubviews[curent] as? LoadingView {
            view.setEnd()
        }
        
        if curent < story.content.count - 1 {
            previous = curent
            curent += 1
            startVideo()
            
            let isIndexValid = playerLayers.indices.contains(curent + 1)
            
            if !isIndexValid && (curent + 1) <= story.content.count - 1,
<<<<<<< HEAD
                let urlContent = story.content[curent + 1].content,
                let url = URL(string: urlContent) {
=======
                let urlContent = story.content[curent + 1].stream,
                let url = URL(string: urlContent){
                
                let player = AVPlayer(url: url)
                player.actionAtItemEnd = .none
                player.play()
                player.pause()
                
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = UIScreen.main.bounds
                playerLayer.videoGravity = .resizeAspectFill
>>>>>>> 9c6344905d09454e9a71949614210f6521fce438
                
                play(with: url) { player in
                    let playerLayer = AVPlayerLayer(player: player)
                    playerLayer.frame = UIScreen.main.bounds
                    playerLayer.videoGravity = .resizeAspectFill
                    
                    self.playerLayers.append(playerLayer)
                }
            }
            
        } else if curent == story.content.count - 1 {
            dismissVideo()
        }
        
    }
    
    func setBackground() {        
        if let story = story, let thumbnailUrl = story.content[curent].thumbnailUrl, let url = URL(string: thumbnailUrl) {
            UIImage.setImage(from: url) { image in
                DispatchQueue.main.async {
                    self.video.addBackground(image: image)
                }
            }
        }
    }
    
    @objc func tapCenter() {
        if let player = playerLayerCurrent.player, let status = PlayerStatus(rawValue: player.rate) {
            
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
                
                pauseImage.image = PlayerStatus.pause.image
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.pauseView.alpha = 0.0
                }, completion: { (bool) in
                    self.pauseView.isHidden = true
                })
            case .play:
                player.pause()
                
                pauseImage.image = PlayerStatus.play.image
                
                leftView.isHidden = true
                rightView.isHidden = true
                
                timer?.invalidate()
            }
        }
    }
    
    @objc func dismissVideo() {
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

extension VideoViewController: AVAssetDownloadDelegate {
    
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
//        UserDefaults.standard.set(location.relativePath, forKey: "assetPath")
        print("Done")
        
//        let
        
//        self.storage?.async.setObject(video, forKey: outputURL.absoluteString, completion: { _ in })
    }
    
    
}

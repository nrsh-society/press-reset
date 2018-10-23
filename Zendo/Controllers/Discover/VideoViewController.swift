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

enum PlayerStatus: Float {
    case pause = 0.0
    case play = 1.0
}

class VideoViewController: UIViewController {
    
    var panGR: UIPanGestureRecognizer!
    
    @IBOutlet weak var loadStackView: UIStackView!
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
    
//    var names = [
//        "https://s3-us-west-2.amazonaws.com/media.zendo.tools/1st_tutorial_iphone-8.m3u8",
//        "https://s3-us-west-2.amazonaws.com/media.zendo.tools/2nd_tutorial_iphone-8.m3u8",
//        "https://s3-us-west-2.amazonaws.com/media.zendo.tools/3rd_tutorial_iphone-8.m3u8",
//        "https://s3-us-west-2.amazonaws.com/media.zendo.tools/4th_tutorial_iphone-8.m3u8",
//        "https://s3-us-west-2.amazonaws.com/media.zendo.tools/5th_tutorial_iphone-8.m3u8"
//    ]
    var names = [
        "Mount",
        "Mount2",
        "Sea"
    ]
    
    var playerObserver: Any?
    var story: Story?
    
    let interval = CMTime(seconds: 1.0, preferredTimescale: 1)
    //        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    
    let mainQueue = DispatchQueue.main
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
        video.addGestureRecognizer(panGR)
        
        if let story = story, let thumbnailUrl = story.thumbnailUrl {
            UIImage.imageFromUrl(urlString: thumbnailUrl) { image in
                DispatchQueue.main.async {
                    self.video.backgroundColor = UIColor(patternImage: image)
                }
            }
        }
        
        for i in 0..<names.count {
            
            guard let path = Bundle.main.path(forResource: names[i], ofType: "MOV") else { return }
            
            let url = URL(fileURLWithPath: path)
//                        if let url = URL(string: names[i]) {
            
            
            let player = AVPlayer(url: url)
            player.actionAtItemEnd = .none
            player.play()
            player.pause()
            
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = UIScreen.main.bounds
            playerLayer.videoGravity = .resizeAspectFill
            
            playerLayers.append(playerLayer)
            
            loadStackView.addArrangedSubview(LoadingView())
            
            //            }
            
        }
        
        startVideo()
        
        let grLeft = UITapGestureRecognizer(target: self, action: #selector(tapLeft))
        leftView.addGestureRecognizer(grLeft)
        
        let grRight = UITapGestureRecognizer(target: self, action: #selector(tapRight))
        rightView.addGestureRecognizer(grRight)
        
        let grCenter = UITapGestureRecognizer(target: self, action: #selector(tapCenter))
        centerView.addGestureRecognizer(grCenter)
        
        modalPresentationCapturesStatusBarAppearance = true
        
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
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
        
        playerObserver = playerLayerCurrent.player?.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) { time in
            
            let duration = Float(time.timescale / 100000000)
            let currentTime = Float(CMTimeGetSeconds(time))
            
//            print("currentTime - " + currentTime.description)
//            print("duration - " + duration.description)
            
            if currentTime >= duration && duration > 0.0 {
                self.tapRight()
                return
            } else {
                if let view = self.loadStackView.arrangedSubviews[self.curent] as? LoadingView {
                    let t = Double(currentTime) / Double(duration)
//                    print("t - "  + t.description)
//                    print("---------")
                    view.setCurent(t)
                }
            }
            
            //            let r = currentTime - lastSecond
            //            print("r - " + r.description)
//            let status = PlayerStatus(rawValue: self.video.player!.rate)!
//            print(status)
            //            if r < 1.0 && duration > 0.0 && lastSecond > 0.0{
            //                self.tapRight()
            //            }
            
            //            lastCurrentTime = Double(currentTime)
            
        }
    }
    
    static func loadFromStoryboard() -> VideoViewController {
        return UIStoryboard(name: "Discover", bundle: nil).instantiateViewController(withIdentifier: "VideoViewController") as! VideoViewController
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
        print("tapLeft")
        
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
        print("tapRight")
        
        if let view = loadStackView.arrangedSubviews[curent] as? LoadingView {
            view.setEnd()
        }
        
        if curent < names.count - 1 {
            previous = curent
            curent += 1
            startVideo()
        } else if curent == names.count - 1 {
            dismissVideo()
        }
        
    }
    
    func setBackground() {
        if let story = story, let thumbnailUrl = story.content[curent].thumbnailUrl {
            UIImage.imageFromUrl(urlString: thumbnailUrl) { image in
                DispatchQueue.main.async {
                    self.video.backgroundColor = UIColor(patternImage: image)
                    
                }
            }
        }
    }
    
    @objc func tapCenter() {
        print("tapCenter")
        
        if let player = playerLayerCurrent.player, let status = PlayerStatus(rawValue: player.rate) {
            switch status {
            case .pause:
                player.play()
            case .play:
                player.pause()
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

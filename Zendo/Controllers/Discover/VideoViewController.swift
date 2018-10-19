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
    
    var idAnim = ""
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
    @IBOutlet weak var video: DiscoverVideo! {
        didSet {
            video.hero.id = idAnim
        }
    }
    
    var count = 3
    var curent = 0
    
    var timer: Timer?
    
    var avArray = [AVPlayer]()
    var avArrayItem = [AVPlayerItem]()
    var names = ["Mount", "Mount2", "Sea"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        video.addBackground()
        
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
                video.addGestureRecognizer(panGR)
        
    
        for i in 0..<count {
            loadStackView.addArrangedSubview(LoadingView())
            
            guard let path = Bundle.main.path(forResource: names[i], ofType: "MOV") else { return }
            
            let player = AVPlayer(url: URL(fileURLWithPath: path))
            player.actionAtItemEnd = .none
            player.play()
            player.pause()
            avArray.append(player)
            let item = AVPlayerItem(url: URL(fileURLWithPath: path))
            avArrayItem.append(item)
        }
        
        startVideo()

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
            if let currentItem = self.video.player?.currentItem {
                let duration = currentItem.duration.seconds
                let currentTime = currentItem.currentTime().seconds

                if currentTime >= duration {
                    self.tapRight()
                } else {
                    if let view = self.loadStackView.arrangedSubviews[self.curent] as? LoadingView {
                        view.setCurent(currentTime / duration)
                    }
                }
            }
        })
        
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
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }

    
    func nameVideo() -> String{
        switch curent {
        case 0: return "Mount"
        case 1: return "Mount2"
        case 2: return "Sea"
        default: return ""
        }
    }
    
    func startVideo() {
        print(curent)

        if video.player == nil {
            video.createBackground(playernew: avArray[curent])
            video.play()
//            video.createBackground(playernew: avArray[curent + 1])
        } else {
            video.replaceVideo(item: avArrayItem[curent], playernew: avArray[curent])

//            video.createBackground(playernew: avArray[curent])
            
//            guard let path = Bundle.main.path(forResource: "Mount2", ofType: "MOV") else { return }
//
//            let player = AVPlayer(url: URL(fileURLWithPath: path))
//            player.actionAtItemEnd = .none
//            video.replaceVideo(playernew: player)
//            video.play()
//            video.player!.pause()
//            video.player = nil
//            video.player!.
//            video.player = avArray[curent]
//            video.player!.seek(to: kCMTimeZero)
//            video.player!.currentItem!.seek(to: kCMTimeZero) { (seek) in
//
//            }
//            video.player!.play()
            
//            video.replaceVideo(item: avArrayItem[curent])
//            if curent < count - 1{
//                video.createBackground(playernew: avArray[curent + 1])
//            }
//            if video.isOne {
//                video.playerLayer?.removeFromSuperlayer()
//                video.playTwo()
//                video.createBackground(playernew: avArray[curent])
//            } else {
//                video.playerLayerTwo?.removeFromSuperlayer()
//                video.play()
//                video.createBackgroundTwo(playernew: avArray[curent])
//            }
            
        }
    }

    
    @objc func tapLeft() {
        print("tapLeft")
        
//        if let image = video.screenshot() {
//            video.backgroundColor = UIColor(patternImage: image)
//        }
        
        if let view = loadStackView.arrangedSubviews[curent] as? LoadingView {
            view.setStart()
        }
        
        if curent > 0 {
            curent -= 1
            if let view = loadStackView.arrangedSubviews[curent] as? LoadingView {
                view.setStart()
            }
            startVideo()
        }
    }
    
    @objc func tapRight() {
        print("tapRight")
        
//        if let image = video.screenshot() {
//            video.backgroundColor = UIColor(patternImage: image)
//        }
        
        
        if let view = loadStackView.arrangedSubviews[curent] as? LoadingView {
            view.setEnd()
        }

        if curent < count - 1 {
            curent += 1
            startVideo()
        } else if curent == count - 1 {
            dismissVideo()
        }
    }
    
    @objc func tapCenter() {
        print("tapCenter")
        
        if let player = video.player, let status = PlayerStatus(rawValue: player.rate) {
            switch status {
            case .pause:
                player.play()
            case .play:
                player.pause()
            }
        }
        
    }
    
    @objc func dismissVideo() {
        timer?.invalidate()
        dismiss(animated: true)
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension UIView {
    
    func addBackground() {
        // screen width and height:
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        
        let imageViewBackground = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: width, height: height))
        imageViewBackground.image = UIImage(named: "welcome")
        
        // you can change the content mode:
        imageViewBackground.contentMode = UIViewContentMode.scaleAspectFill
        
        //        self.addSubview(imageViewBackground)
        //        self.sendSubview(toBack: imageViewBackground)
        
        layer.insertSublayer(imageViewBackground.layer, at: 0)
    }
    
}

//
//  VideoViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 18/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

enum PlayerStatus: Float {
    case pause = 0.0
    case play = 1.0
}

class VideoViewController: UIViewController {
    
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
    @IBOutlet weak var video: DiscoverVideo!
    
    var count = 3
    var curent = 1
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for _ in 0..<count {
            loadStackView.addArrangedSubview(LoadingView())
        }
        
        startVideo()

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
            if let currentItem = self.video.player?.currentItem {
                let duration = currentItem.duration.seconds
                let currentTime = currentItem.currentTime().seconds

                if currentTime >= duration {
                    self.tapRight()
                } else {
                    if let view = self.loadStackView.arrangedSubviews[self.curent - 1] as? LoadingView {
                        view.setCurent(currentTime / duration)
                    }
                }
            }
        })
        
        let gr = UISwipeGestureRecognizer(target: self, action: #selector(dismissVideo))
        gr.direction = .down
        video.addGestureRecognizer(gr)
        
        let grLeft = UITapGestureRecognizer(target: self, action: #selector(tapLeft))
        leftView.addGestureRecognizer(grLeft)
        
        let grRight = UITapGestureRecognizer(target: self, action: #selector(tapRight))
        rightView.addGestureRecognizer(grRight)
        
        let grCenter = UITapGestureRecognizer(target: self, action: #selector(tapCenter))
        centerView.addGestureRecognizer(grCenter)
        
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    func nameVideo() -> String{
        switch curent {
        case 1: return "Mount"
        case 2: return "Mount2"
        case 3: return "Sea"
        default: return ""
        }
    }
    
    func startVideo() {
        if video.player == nil {
            video.createBackground(name: nameVideo(), type: "MOV")
        } else {
            video.replaceVideo(name: nameVideo(), type: "MOV")
        }
    }

    
    @objc func tapLeft() {
        print("tapLeft")
        
        if let image = video.screenshot() {
            video.backgroundColor = UIColor(patternImage: image)
        }
        
        if let view = loadStackView.arrangedSubviews[curent - 1] as? LoadingView {
            view.setStart()
        }
        
        if curent > 1 {
            curent -= 1
            if let view = loadStackView.arrangedSubviews[curent - 1] as? LoadingView {
                view.setStart()
            }
            startVideo()
        }
    }
    
    @objc func tapRight() {
        print("tapRight")
        
        if let image = video.screenshot() {
            video.backgroundColor = UIColor(patternImage: image)
        }
        
        
        if let view = loadStackView.arrangedSubviews[curent - 1] as? LoadingView {
            view.setEnd()
        }

        if curent < count {
            curent += 1
            startVideo()
        } else if curent == count {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //        setNeedsStatusBarAppearanceUpdate()
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

//
//  DiscoverVideo.swift
//  Zendo
//
//  Created by Anton Pavlov on 19/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import AVFoundation
import UIKit

class AVPlayerView: UIView {
    override class var layerClass: Swift.AnyClass {
        return AVPlayerLayer.self
    }
}

class DiscoverVideo: UIView {
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    var playerTwo: AVPlayer?
    var playerLayerTwo: AVPlayerLayer?
    
    var isOne = true
    
//    func createBackground(name: String, type: String) {
//        guard let path = Bundle.main.path(forResource: name, ofType: type) else { return }
//
//        player = AVPlayer(url: URL(fileURLWithPath: path))
//        player?.actionAtItemEnd = AVPlayerActionAtItemEnd.none;
//        playerLayer = AVPlayerLayer(player: player)
//        playerLayer!.frame = self.frame
//        playerLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        layer.insertSublayer(playerLayer!, at: 1)
//        player?.seek(to: kCMTimeZero)
//        player?.play()
//    }
    
    func createBackground(playernew: AVPlayer) {
        
        player = playernew
        player!.actionAtItemEnd = .none
        playerLayer = AVPlayerLayer(player: player)
        playerLayer!.frame = self.frame
        playerLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
    }
    
//    func replaceVideo(playernew: AVPlayer) {
////        player?.pause()
////        player = nil
//        player = playernew
//        player!.actionAtItemEnd = .none
//        player.
//        playerLayer = AVPlayerLayer(player: player)
//        playerLayer!.frame = self.frame
//        playerLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
////        layer.insertSublayer(playerLayer!, at: 1)
//        layer.replaceSublayer(playerLayer!, with: playerLayer!)
//        player?.seek(to: kCMTimeZero)
//        player?.play()
//    }
    
    func play() {
        layer.insertSublayer(playerLayer!, at: 1)
        player?.seek(to: kCMTimeZero)
        player?.play()
    }
    
//    func createBackgroundTwo(playernew: AVPlayer) {
//        playerTwo = playernew
//        playerTwo?.actionAtItemEnd = AVPlayerActionAtItemEnd.none;
//        playerLayerTwo = AVPlayerLayer(player: playerTwo)
//        playerLayerTwo!.frame = self.frame
//        playerLayerTwo!.videoGravity = AVLayerVideoGravity.resizeAspectFill
//    }
//    
//    func playTwo() {
//        layer.insertSublayer(playerLayerTwo!, at: 1)
//        playerTwo?.seek(to: kCMTimeZero)
//        playerTwo?.play()
//    }
    
   
    
    func replaceVideo(item: AVPlayerItem, playernew: AVPlayer) {
        
//        player?.pause()
        player?.replaceCurrentItem(with: item)

//        player = nil
//        player = playernew
//        player?.seek(to: kCMTimeZero)
//        player?.play()
        
    }
    
   
    
    func screenshot() -> UIImage? {
        guard let time = player?.currentItem?.currentTime() else {
            return nil
        }
        
        return screenshotCMTime(cmTime: time)
    }
    
    private func screenshotCMTime(cmTime: CMTime) -> UIImage? {
        guard let player = player , let asset = player.currentItem?.asset, var timePicture = player.currentItem?.currentTime()  else {
            return nil
        }
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero
        
        let ref = try? imageGenerator.copyCGImage(at: cmTime, actualTime: &timePicture)
        
        if let ref = ref {
            return UIImage(cgImage: ref)
        }
        return nil
        
    }
    
}

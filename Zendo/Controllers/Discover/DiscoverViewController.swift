//
//  DiscoverViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 18/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import AVFoundation
import UIKit

class DiscoverVideo: UIView {
    var player: AVPlayer?
    
    func createBackground(name: String, type: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else { return }
        
        player = AVPlayer(url: URL(fileURLWithPath: path))
        player?.actionAtItemEnd = AVPlayerActionAtItemEnd.none;
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.frame
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        layer.insertSublayer(playerLayer, at: 0)
        player?.seek(to: kCMTimeZero)
        player?.play()
    }
    
    func replaceVideo(name: String, type: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: type), player != nil  else { return }

        player?.replaceCurrentItem(with: AVPlayerItem(url: URL(fileURLWithPath: path)))
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

class DiscoverViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let space: CGFloat = 9

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        collectionView.register(DiscoverCollectionViewCell.nib, forCellWithReuseIdentifier: DiscoverCollectionViewCell.reuseIdentifierCell)

        // Do any additional setup after loading the view.
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

//MARK: - UICollectionViewDataSource

extension DiscoverViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiscoverCollectionViewCell.reuseIdentifierCell, for: indexPath) as! DiscoverCollectionViewCell
        
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showVideo", sender: self)
    }
    
}

//MARK: - UICollectionViewDelegateFlowLayout

extension DiscoverViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let padding: CGFloat = space * 3
        let collectionViewSize = collectionView.frame.size.width - padding
        let collectionViewSizeHeight = collectionView.frame.size.height - padding
        
        return CGSize(width: (collectionViewSize/2), height: (collectionViewSizeHeight - space * 2))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: space, left: space, bottom: space, right: space)
    }

    
}

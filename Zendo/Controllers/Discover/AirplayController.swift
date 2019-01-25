//
//  AirplayController.swift
//  Harness
//
//  Created by Douglas Purdy on 1/19/19.
//  Copyright © 2019 Douglas Purdy. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class AirplayController: UIViewController {
    
    @IBOutlet weak var tickerLabel: UILabel!
    
    var newWindow : UIWindow?
    var url : String?
    var avItem : AVPlayerItem?
    
    class func loadFromStoryboard() -> AirplayController
    {
        let storyboard =  UIStoryboard(name: "AirplayController", bundle: nil).instantiateViewController(withIdentifier: "AirplayController") as! AirplayController
        
        storyboard.registerAsSecondScreen()
        
        return storyboard
 
    }
    
    func updateMedia(_ item : AVPlayerItem)
    {
        
        self.avItem = item
        
        if let bounds = self.newWindow?.bounds
        {
            let media = self.avItem?.asset
            let item = AVPlayerItem(asset: media!)
            let video = AVPlayer(playerItem: item)
            let layer  = AVPlayerLayer(player: video)
            
            layer.frame = bounds
            layer.videoGravity = AVLayerVideoGravity.resize
            self.view.layer.insertSublayer(layer, at: 0)
            
            video.play()
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let bounds = self.newWindow?.bounds
        {
            let media = self.avItem?.asset
            let item = AVPlayerItem(asset: media!)
            let video = AVPlayer(playerItem: item)
            let layer  = AVPlayerLayer(player: video)
            
            layer.frame = bounds
            layer.videoGravity = AVLayerVideoGravity.resize
            self.view.layer.insertSublayer(layer, at: 0)
            
            video.play()
        }
    }
    
    func updateTicker(text: String)
    {
        self.tickerLabel.text = text
    }
    
    func registerAsSecondScreen()
    {
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIScreenDidConnect,
                                               object: nil, queue: nil)
        {
            (notification) in
            
            let newScreen = notification.object as! UIScreen
            let screenDimensions = newScreen.bounds
            
            self.newWindow = UIWindow(frame: screenDimensions)
            self.newWindow?.screen = newScreen
            
            self.newWindow?.rootViewController = self
            
            if let bounds = self.newWindow?.bounds
            {
                self.view.bounds = bounds
            }
            
            //let view = UIScreen.main.snapshotView(afterScreenUpdates: true)
            
            // You must show the window explicitly.
            self.newWindow?.isHidden = false
            
        }
        
        NotificationCenter.default.addObserver(forName:NSNotification.Name.UIScreenDidDisconnect,
                                               object: nil, queue: nil)
        {
            (notification) in
            
            //let newScreen = notification.object as! UIScreen
            
            self.dismiss(animated: true, completion: nil)
            
             self.newWindow?.isHidden = true
            
             self.newWindow = nil
            
            
        }
        
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sample),
                                               name: NSNotification.Name("sample"),
                                               object: nil)
        
       
    }
    
    @objc func sample(notification: NSNotification)
    {
        if let ticker = self.tickerLabel
        {
            DispatchQueue.main.async
                {
                    if let sample = notification.object as? [String : String]
                    {
                        let text_hrv = sample["sdnn"]!
                        let double_hrv = Double(text_hrv)!.rounded()
                        let int_hrv = Int(double_hrv)
                        
                        UIView.animate(withDuration: 0.5, animations:
                        {
                            ticker.alpha = ticker.alpha == 0.5 ? 1 : 0.5
                        })
                        
                        ticker.text = int_hrv.description
                    }
            }
        }
        
    }
    
}

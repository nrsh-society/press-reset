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
import Firebase
import FirebaseDatabase

class AirplayController: UIViewController {
    
    @IBOutlet weak var tickerLabel: UILabel!
    @IBOutlet weak var partyConsole: UITextView!
    
    var screenConnectObserver : Any?
    var screenDisconnectObserver : Any?
    
    var newWindow : UIWindow?
    var avItem : AVPlayerItem?
    var avLayer : AVPlayerLayer?
    var avPlayer : AVPlayer?
    var url : URL?
    
    class func loadFromStoryboard(_ url: URL) -> AirplayController
    {
        let storyboard =  UIStoryboard(name: "AirplayController", bundle: nil).instantiateViewController(withIdentifier: "AirplayController") as! AirplayController
        
        storyboard.setupDisplayCallbacks(url: url)
        
        return storyboard
 
    }
    
    func setupDisplayCallbacks(url: URL)
    {
        if(screenConnectObserver == nil)
        {
            screenConnectObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name.UIScreenDidConnect,
                object: nil, queue: nil)
            {
                (notification) in
                
                let newScreen = notification.object as! UIScreen
                
                if self.newWindow == nil
                {
                    let screenDimensions = newScreen.bounds
                    
                    self.newWindow = UIWindow(frame: screenDimensions)
                    self.newWindow?.screen = newScreen
                
                    self.newWindow?.rootViewController = self
                
                    self.newWindow?.isHidden = false
                    
                    let item = AVPlayerItem(url: url)
                    
                    self.updateMedia(item)
                
                }
            
                NotificationCenter.default.removeObserver(self.screenConnectObserver!)
                
                self.screenConnectObserver = nil
            }
            
        }
        
        if(screenDisconnectObserver == nil)
        {
    
            screenDisconnectObserver = NotificationCenter.default.addObserver(
                forName:NSNotification.Name.UIScreenDidDisconnect,
                object: nil, queue: nil)
            {
                (notification) in
                

                let _ = notification.object as! UIScreen
                
                if self.newWindow != nil
                {
                    self.dismiss()
                }
                
                NotificationCenter.default.removeObserver(self.screenDisconnectObserver!)
                
                self.screenDisconnectObserver = nil
            }
        }
    }
    
    func dismiss()
    {
        if let observer = self.screenConnectObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
        
        if let observer = self.screenDisconnectObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
        
        self.avPlayer?.pause()
        self.dismiss(animated: true)
        self.newWindow?.isHidden = true
        self.newWindow = nil
        
    }
    
    func updateMedia(_ item : AVPlayerItem)
    {
        self.avItem = item
        
        if let layer = self.avLayer
        {
            self.avPlayer?.pause()
            layer.removeFromSuperlayer()
        }
        
        let media = self.avItem?.asset
        let item = AVPlayerItem(asset: media!)
        self.avPlayer = AVPlayer(playerItem: item)
        self.avPlayer?.allowsExternalPlayback = false
        self.avLayer  = AVPlayerLayer(player: self.avPlayer)
        
        self.avLayer?.frame = (self.view.window?.bounds)!
        self.avLayer?.videoGravity = AVLayerVideoGravity.resize
        self.view.layer.insertSublayer(self.avLayer!, at: 0)
        
        self.avPlayer?.play()
        
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        self.avPlayer?.pause()
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sample),
                                               name: NSNotification.Name("sample"),
                                               object: nil)
        
    }
    
    func updateTicker(text: String)
    {
        self.tickerLabel.text = text
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

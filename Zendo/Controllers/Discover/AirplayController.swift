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
    
    
    var avItem : AVPlayerItem?
    var avLayer : AVPlayerLayer?
    var avPlayer : AVPlayer?
    
    class func loadFromStoryboard() -> AirplayController
    {
        let storyboard =  UIStoryboard(name: "AirplayController", bundle: nil).instantiateViewController(withIdentifier: "AirplayController") as! AirplayController
        
        return storyboard
 
    }
    
    func pauseMedia()
    {
        if let player = self.avPlayer
        {
            player.pause()
        }
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
        self.avLayer  = AVPlayerLayer(player: self.avPlayer)
        
        self.avLayer?.frame = (self.view.window?.bounds)!
        self.avLayer?.videoGravity = AVLayerVideoGravity.resize
        self.view.layer.insertSublayer(self.avLayer!, at: 0)
        
        self.avPlayer?.play()
        
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sample),
                                               name: NSNotification.Name("sample"),
                                               object: nil)
        
        let database = Database.database().reference()
        
        let sample = database.child("samples")
        
        let refHandle = sample.observe(DataEventType.value, with:
        {
            (snapshot) in
            
            let samples = snapshot.value as? [String : [String : AnyObject]] ?? [:]
            
            samples.forEach({ (arg0) in
                
                let (key, value) = arg0
                
                let data = value["data"] as! [String : String]
                
                let text_hrv = data["sdnn"]!
                let double_hrv = Double(text_hrv)!.rounded()
                let int_hrv = Int(double_hrv)
                
                let  text_email = value["email"]!
                
                let entry = (text_email as! String) + ": " + int_hrv.description + "\n"
                
                DispatchQueue.main.async
                {
                    self.partyConsole.text.append(entry)
                        
                    let lastLine = NSMakeRange(self.partyConsole.text.count - 1, 1);
                    self.partyConsole.scrollRangeToVisible(lastLine)
                }
            })
        })
        
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

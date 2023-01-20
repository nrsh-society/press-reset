//
//  AudioFeedback.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 9/17/22.
//  Copyright © 2022 zenbf. All rights reserved.
//

import Foundation
import AVFAudio
import AVFoundation

class AudioFeedback {
        
    static let availableSounds = ["Rain", "Birds", "Stream", "Crystal"]
    
    static var currentSound: Int  {
        get
        {
            
            if let value = UserDefaults.standard.object(forKey: "audioFeedbackSelection")
            {
                return value as! Int
            }
            else
            {
                return 0
            }
        }
        
        set
        {
            UserDefaults.standard.set(newValue, forKey: "audioFeedbackSelection")
        }
    }
    
    static var rate: Float = 1.0
    
    static var avPlayer: AVPlayer?
    
    static var isPlaying = false
    
    static func play() {
        
        if(!isPlaying) {
            
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeDefault)
            
            try? AVAudioSession.sharedInstance().setActive(true)
            
            /* looping code*/
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.avPlayer?.currentItem, queue: .main) { [self] _ in
                self.avPlayer?.seek(to: kCMTimeZero)
                self.avPlayer?.play()
            }
            
            let currentSoundName = availableSounds[currentSound].lowercased()
            
            self.avPlayer = AVPlayer(url: Bundle.main.url(forResource: currentSoundName, withExtension: "mp3")!)
            
            self.avPlayer?.currentItem?.audioTimePitchAlgorithm = .spectral
            
            self.avPlayer?.play()
        
            self.isPlaying = true
        
        } else {
            
            self.avPlayer?.rate = self.rate
        }
        
    }
    
    static func stop() {
        
        self.avPlayer?.pause()
        self.isPlaying = false
    }
    
}

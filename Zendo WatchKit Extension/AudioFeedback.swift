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
import CoreMedia

class AudioFeedback {
    
    static let availableSounds = ["Rain", "Birds", "Stream", "Ocean"]
    
    static var currentSound: Int {
        get {
            if let value = UserDefaults.standard.object(forKey: "audioFeedbackSelection") as? Int {
                return value
            } else {
                return 0
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "audioFeedbackSelection")
        }
    }
    
    static var rate: Float = 1.0
    static var player: AVAudioPlayer?
    static var isPlaying = false
    
    static func play() {
        if !isPlaying {
            
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeDefault)
            try? AVAudioSession.sharedInstance().setActive(true)
            
            let currentSoundName = availableSounds[currentSound].lowercased()
            if let url = Bundle.main.url(forResource: currentSoundName, withExtension: "mp3") {
                

                self.player = try? AVAudioPlayer(contentsOf: url)
                
                player?.numberOfLoops = -1
                                 
                player?.play()

                isPlaying = true
            }
        } else {
            
        }
    }
    
    static func stop() {
        player?.pause()
        isPlaying = false
    }
}

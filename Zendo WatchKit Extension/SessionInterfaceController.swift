
//
//  TimerInterfaceController.swift
//  Zazen WatchKit Extension
//
//  Created by dmp on 12/29/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class SessionInterfaceController: WKInterfaceController, SessionDelegate {
    
    var _timer: Timer!
    var _session: Session!;
    
    @IBOutlet var timeElapsedLabel: WKInterfaceLabel!
    
     func sessionTick(startDate: Date) {
        
        DispatchQueue.main.async {
            
            let timeElapsed = Int(abs(startDate.timeIntervalSinceNow / 60).rounded());
            
            var value = timeElapsed.description
            
            if timeElapsed < 10 {
                value = "0\(value)"
            }
        
            self.timeElapsedLabel.setText(value)
            
            //#todo: this seems like it is causing a crash during testing.
            //going to comment and move to getting the tick data in the cloud for vr display.
            /*let url = URL(string: "https://api.soundcloud.com/tracks/418761428/download?client_id=7f7f14c97e33d1209679b4f94aead3c1")!
            
            self.presentMediaPlayerController(with: url, options: [WKMediaPlayerControllerOptionsAutoplayKey: 1]) {
                    didPlayToEnd, endTime, error in
                
                if(didPlayToEnd) { self.dismissMediaPlayerController(); }
            }
 
            */
            
            Thread.detachNewThread {
                
                DispatchQueue.main.sync {
                    WKInterfaceDevice.current().play(.success)
                }
                
                Thread.sleep(forTimeInterval: 1)
                
                DispatchQueue.main.sync {
                    WKInterfaceDevice.current().play(.success)
                }
                
            }
            
        }
    }
    
    @IBAction func onDonePress() {
        
        _session.end();
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "AppInterfaceController", context: NSNull())])
    }
    
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
        
        if(context != nil) {
        
            _session = context as! Session
            
            _session.delegate = self
            
            timeElapsedLabel.setText("00")
            
        }
    }

    override func willActivate() {
        
        super.willActivate()
    }
    
    override func didDeactivate() {
    
        super.didDeactivate()

    }

}

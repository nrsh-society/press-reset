//
//  Session.swift
//  Zazen WatchKit Extension
//
//  Created by dmp on 12/29/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import WatchKit
import HealthKit
import Foundation

protocol SessionDelegate {
    
    //fired everytime the session interface should be updated
    func sessionTick(startDate: Date, endDate: Date);
}

class Session : NSObject {
    
    var duration: Int!
    var startDate : Date?;
    var endDate : Date?;
    var lastTick : Date?;
    var workoutSession : HKWorkoutSession?;
    var isRunning : Bool! = false;
    var delegate : SessionDelegate! = nil;
    
    private var _timer : Timer?;
    private let _healthStore = HKHealthStore();
    private let hkType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    private let hkworkT = HKObjectType.workoutType();
    private var samples = [HKCategorySample]();
    
    init(duration: Int) {
        
        super.init();
        
        self.duration = duration;
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .unknown
        
        do {
            workoutSession = try HKWorkoutSession(configuration: configuration)
            
            _healthStore.requestAuthorization(
                toShare: Set([hkType, HKObjectType.workoutType()]),
                read: Set([hkType, HKObjectType.workoutType()]),
                completion: { (success, error) in
                    
                    if(error != nil) {
                        print(error.debugDescription);
                    }
            })
        } catch let error as NSError {
            // Perform proper error handling here...
            fatalError("*** Unable to create the workout session: \(error.localizedDescription) ***")
        }
    }
    
    func start() {
        
        if(!self.isRunning) {
            
            startDate = Date();
            
            endDate = startDate!.addingTimeInterval(Double(duration));
        
            _healthStore.start(workoutSession!);
            
            WKInterfaceDevice.current().play(.start)
            
            createTimer();
            
            self.isRunning = true;
            
        }
        else {
            print("called start on running session")
        }
    }
    
    func end() {
        
        if(!self.isRunning) {
            print("called end on unrunning session");
            return;
        }
        
        WKInterfaceDevice.current().play(.stop)
        
        _healthStore.end(workoutSession!)
        
        self.endDate = Date();
        
        let workout = HKWorkout(activityType: HKWorkoutActivityType.mindAndBody, start: self.startDate!, end: self.endDate!)
        
        _healthStore.save([workout]) { success, error in
            
            if(error != nil) {
                print(error.debugDescription);
            }
            
            self._healthStore.add(self.samples, to: workout) { (success, error) in
                
                if(error != nil) {
                    print(error.debugDescription);
                }
            }
            
        }
        
        invalidate();
        
    }
    
    func createTimer() {
        
        _timer = Timer.scheduledTimer(timeInterval: 60, target:self, selector: #selector(Session.notify), userInfo: nil, repeats: true)
        
        lastTick = Date();
    }
    
    @objc public func notify()  {
        
        let metadata = ["initial_duration": self.duration] as [String:Any]; //add location + heart beat, etc.
        
        let sample = HKCategorySample(type: hkType, value: 0, start: lastTick!, end: Date(), metadata: metadata)
        
        _healthStore.save([sample]) { _,_ in
            
            self.samples.append(sample);
        }
        
        WKInterfaceDevice.current().play(.success)
        
        self.delegate.sessionTick(startDate: self.startDate!, endDate: self.endDate!);
        
        lastTick = Date();
        
    }
    
    func invalidate() {
        
        _timer!.invalidate();
        self.isRunning = false;
        
    }
}

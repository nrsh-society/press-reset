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
import CoreMotion
import CoreFoundation

protocol SessionDelegate {
    
    //fired everytime the session interface should be updated
    func sessionTick(startDate: Date);
}

struct Rotation  {
    var pitch : Double = 0.0
    var roll : Double = 0.0
    var yaw : Double = 0.0
}

class Session : NSObject {
    var startDate : Date?
    var endDate : Date?
    var lastSample = Date()
    var workoutSession : HKWorkoutSession?
    var isRunning : Bool! = false
    var delegate : SessionDelegate! = nil
    var rotation = Rotation(pitch: 0.0, roll: 0.0, yaw: 0.0)
    var motion : Double = 0.0
    var heartRate : Double = 0.0
    var heartSDNN : Double = 0.0
    
    private var _sampleTimer : Timer?;
    private var _notifyTimer : Timer?;
    
    private let _healthStore = HKHealthStore();
    private let hkType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    private let hkworkT = HKObjectType.workoutType();
    private var samples = [HKCategorySample]();
    private let motionManager = CMMotionManager();
    
    override init() {
        
        super.init();
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .unknown
        
        do {
            workoutSession = try HKWorkoutSession(configuration: configuration)
            
            //#todo: add the workout management to the wrapper too
            ZBFHealthKit.getPermissions()
            
        } catch let error as NSError {
            //$todo: clean up all error handling
            fatalError("*** Unable to create the workout session: \(error.localizedDescription) ***")
        }
    }
    
    func start() {
        
        if(!self.isRunning) {
            
            self.startDate = Date();
            
            motionManager.startDeviceMotionUpdates();
            
            _healthStore.start(workoutSession!);
            
            WKInterfaceDevice.current().play(.start)
            
            createTimers();
            
            self.isRunning = true;
            
        } else {
            print("called start on running session")
        }
    }
    
    func end() {
        
        if(!self.isRunning) {
            print("called end on unrunning session");
            return;
        }
        
        motionManager.stopDeviceMotionUpdates()
        
        WKInterfaceDevice.current().play(.stop)
        
        _healthStore.end(workoutSession!)
        
        self.endDate = Date();
        
        let workout = HKWorkout(activityType: HKWorkoutActivityType.mindAndBody,
                                start: self.startDate!, end: self.endDate!)
        
        _healthStore.save([workout]) { success, error in
            
            if(error != nil) {
                print(error.debugDescription);
            }
            
            self._healthStore.add(self.samples, to: workout) {
                (success, error) in
                
                if(error != nil) {
                    print(error.debugDescription);
                }
            }
            
        }
        
        invalidate();
        
    }
    
    func createTimers() {
        
        _sampleTimer = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(Session.sample), userInfo: nil, repeats: true)
        
        _notifyTimer = Timer.scheduledTimer(timeInterval: 60, target:self, selector: #selector(Session.notify), userInfo: nil, repeats: true)
        
    }
    
    @objc public func notify()  {
                
        self.delegate.sessionTick(startDate: self.startDate!);
        
    }
    
    @objc public func sample()  {
        

        if let deviceMotion = self.motionManager.deviceMotion {
            
            self.rotation.pitch = deviceMotion.rotationRate.x
            self.rotation.roll = deviceMotion.rotationRate.y
            self.rotation.yaw = deviceMotion.rotationRate.z
            
        }
    
        self.motion = abs(self.rotation.pitch) + abs(self.rotation.roll) + abs(self.rotation.yaw)
        
        self.motion = self.motion / 3
        
        self.motion = Double(round(100*self.motion)/100)
    
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        
        let heartRateSDNNType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let heartRateSDNNPredicate: NSPredicate? = HKQuery.predicateForSamples(withStart: yesterday, end: Date(), options: .strictEndDate)
        
        _healthStore.execute(HKStatisticsQuery(quantityType: heartRateSDNNType,
                                               quantitySamplePredicate: heartRateSDNNPredicate,
                                               options: .discreteAverage) { query, result, error in
                                                
                                                if(error != nil) {
                                                    print(error.debugDescription);
                                                }
                                                
                                                if let sdnn = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                                    
                                                    self.heartSDNN = sdnn
                                                }
        })
        
        let heartRateType =
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
        
        let heartRatePredicate: NSPredicate? = HKQuery.predicateForSamples(withStart: self.startDate, end: Date(), options: .strictEndDate)
        
        
        _healthStore.execute(HKStatisticsQuery(quantityType: heartRateType,
                                               quantitySamplePredicate: heartRatePredicate,
                                               options: .discreteAverage) { query, result, error in
                                                
                                                if(error != nil) {
                                                    print(error.debugDescription);
                                                }
                                            
                                                if let heartRate = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "count/s")) {
                                                    
                                                    self.heartRate = heartRate
                                                }
                                                
        })
        
        
        let metadata = ["now": Date().description,
                        "motion": motion.description,
                        "sdnn": heartSDNN.description,
                        "heart": heartRate.description,
                        "pitch" : self.rotation.pitch.description,
                        "roll" : self.rotation.roll.description,
                        "yaw": self.rotation.yaw.description
                        ] as [String: String]
        
        let values = metadata as [String: Any]
        
        //#todo: should this be another lighterweight sample type?
        let sample = HKCategorySample(type: self.hkType, value: 0, start: self.lastSample, end: Date(), metadata: values )
        
        self._healthStore.save([sample]) { _,_ in
            
            self.samples.append(sample);
            
        }
        
        lastSample = Date();
        
/*      #todo: post dataset to server to drive av
        do {
            
            let json = try JSONSerialization.data(withJSONObject: metadata, options: []).description
            
            let serviceURL = URL(string:"https://zendo-v1.firebaseio.com/zazen")!
            var request = URLRequest(url: serviceURL)
            request.httpMethod = "POST"
        
            let config = URLSessionConfiguration()
            config.allowsCellularAccess = true;
            
            let session = URLSession(configuration: config)
            let task = session.uploadTask(with: request, from: json.data(using: .utf8)!)
            
            task.resume()
            
        } catch {}
 
 */
    }
    
    func invalidate() {
        
        _sampleTimer!.invalidate();
        _notifyTimer!.invalidate();
        self.isRunning = false;
        
    }
}

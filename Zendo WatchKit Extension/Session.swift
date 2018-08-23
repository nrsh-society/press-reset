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
import WatchConnectivity

protocol SessionDelegate {
    
    //fired everytime the session interface should be updated
    func sessionTick(startDate: Date)
}

struct Rotation  {
    var pitch: Double = 0.0
    var roll: Double = 0.0
    var yaw: Double = 0.0
}

struct Options {
    
    var hapticStrength = 1
}

class Session: NSObject, SessionCommands {
    
    var startDate: Date?
    var endDate: Date?
    var workoutSession: HKWorkoutSession?
    var isRunning = false
    var delegate: SessionDelegate! = nil
    var rotation = Rotation(pitch: 0.0, roll: 0.0, yaw: 0.0)
    var motion = 0.0
    var heartRate = 0.0
    var heartSDNN = 0.0
    
    private var sampleTimer: Timer?
    private var notifyTimer: Timer?
    
    private let healthStore = HKHealthStore()
    private let hkType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    private let hkworkT = HKObjectType.workoutType()
    private var samples = [HKCategorySample]()
    private let motionManager = CMMotionManager()
    
    var metadataWork = [String: Any]()
    
    static var options = Options(hapticStrength: 1)
    
    static var current: Session?
    
    override init() {
        super.init()
        
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
        
        if !self.isRunning {
            self.startDate = Date()
            
            motionManager.startDeviceMotionUpdates()
            
            healthStore.start(workoutSession!)
            
            WKInterfaceDevice.current().play(.start)
            
            createTimers()
            
            self.isRunning = true
        } else {
            print("called start on running session")
        }
    }
    
    func end() {
        
        if !self.isRunning {
            print("called end on unrunning session")
            return
        }
        
        motionManager.stopDeviceMotionUpdates()
        
        WKInterfaceDevice.current().play(.stop)
        
        healthStore.end(workoutSession!)
        
        
        self.endDate = Date()
        
        // let workout = HKWorkout(activityType: .mindAndBody, start: self.startDate!, end: self.endDate!)
        let workout = HKWorkout(activityType: .mindAndBody, start: self.startDate!, end: self.endDate!, workoutEvents: nil, totalEnergyBurned: nil, totalDistance: nil, totalSwimmingStrokeCount: nil, device: nil, metadata: metadataWork)
        
        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let mindfullSample = HKCategorySample(type:mindfulType, value: 0, start: self.startDate!, end: self.endDate!)
        
        healthStore.save([workout]) { success, error in
            
            guard error == nil else {
                print(error.debugDescription)
                return
            }
            
            self.healthStore.add([mindfullSample], to: workout, completion: { (success, error) in
                
                self.sendMessage(["watch": "reload"], replyHandler: { (replyMessage) in
                    
                }, errorHandler: { (error) in
                    print(error.localizedDescription)
                })
                
            })
            
        }
        
        invalidate()
        
    }
    
    func createTimers() {
        sampleTimer = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(Session.sample), userInfo: nil, repeats: true)
        
        notifyTimer = Timer.scheduledTimer(timeInterval: 60, target:self, selector: #selector(Session.notify), userInfo: nil, repeats: true)
    }
    
    @objc func notify()  {
        
        self.delegate.sessionTick(startDate: self.startDate!);
        
        if Session.options.hapticStrength > 0 {
            
            Thread.detachNewThread {
                for _ in 1...Session.options.hapticStrength {
                    DispatchQueue.main.sync {
                        WKInterfaceDevice.current().play(.success)
                    }
                    
                    Thread.sleep(forTimeInterval: 1)
                }
            }
        }
    }
    
    @objc func sample()  {
        
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
        
        healthStore.execute(HKStatisticsQuery(quantityType: heartRateSDNNType,
                                              quantitySamplePredicate: heartRateSDNNPredicate, options: .discreteAverage) { query, result, error in
                                                
                                                if let error = error {
                                                    print(error.localizedDescription);
                                                } else {
                                                    if let sdnn = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")){
                                                        self.heartSDNN = sdnn
                                                    }
                                                }
        })
        
        let heartRateType =
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
        
        let heartRatePredicate: NSPredicate? = HKQuery.predicateForSamples(withStart: self.startDate, end: Date(), options: .strictEndDate)
        
        
        healthStore.execute(HKStatisticsQuery(quantityType: heartRateType,
                                              quantitySamplePredicate: heartRatePredicate,
                                              options: .discreteAverage) { query, result, error in
                                                
                                                if let error = error {
                                                    print(error.localizedDescription);
                                                } else {
                                                    if let heartRate = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "count/s")) {
                                                        
                                                        self.heartRate = heartRate
                                                    }
                                                }
        })
        
        
        let metadata: [String: Any] = [
            MetadataType.time.rawValue: Date().timeIntervalSince1970.description,
            MetadataType.now.rawValue: Date().description,
            MetadataType.motion.rawValue: motion.description,
            MetadataType.sdnn.rawValue: heartSDNN.description,
            MetadataType.heart.rawValue: heartRate.description,
            MetadataType.pitch.rawValue: self.rotation.pitch.description,
            MetadataType.roll.rawValue: self.rotation.roll.description,
            MetadataType.yaw.rawValue: self.rotation.yaw.description
        ]
        
        let empty = metadataWork.isEmpty ? "" : "/"
        
        for type in metadataTypeArray {
            metadataWork[type.rawValue] = ((metadataWork[type.rawValue] as? String) ?? "") + empty + (metadata[type.rawValue] as! String)
        }
        
        
        
        
        
        //#todo: should this be another lighterweight sample type?
        //        let sample = HKCategorySample(type: hkTypee, value: 0, start: self.lastSample, end: Date(), metadata: metadata)
        
        //        self.healthStore.save([sample]) { _, _ in
        // self.samples.append(sample)
        //        }
        
        // lastSample = Date()
        
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
        sampleTimer!.invalidate()
        notifyTimer!.invalidate()
        self.isRunning = false
    }
}

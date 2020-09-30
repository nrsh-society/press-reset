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
import Mixpanel

protocol SessionDelegate
{
    func sessionTick(startDate: Date, message : String?)
}

struct Rotation
{
    var pitch: Double = 0.0
    var roll: Double = 0.0
    var yaw: Double = 0.0
}

struct Options
{
    var hapticStrength : Int
    {
        get
        {
            if let value = UserDefaults.standard.object(forKey: "hapticStrength")
            {
                return value as! Int
            }
            else
            {
                return 1
            }
        }
        
        set
        {
            UserDefaults.standard.set(newValue, forKey: "hapticStrength")
        }
    }
    
    var retryStrength : Int
    {
        get
        {
            
            if let value = UserDefaults.standard.object(forKey: "retryStrength")
            {
                return value as! Int
            }
            else
            {
                return 1
            }
        }
        
        set
        {
            UserDefaults.standard.set(newValue, forKey: "retryStrength")
        }
    }
}

class Session: NSObject, SessionCommands, BluetoothManagerDataDelegate {
    
    var startDate: Date?
    var endDate: Date?
    var workoutSession: HKWorkoutSession?
    var isRunning = false
    var delegate: SessionDelegate! = nil
    var rotation = Rotation(pitch: 0.0, roll: 0.0, yaw: 0.0)
    var motion = 0.0
    var heartRate = 0.0
    public var heartSDNN = 0.0
    var heartRateSamples = [Double]()
    var heartRateRangeSamples = [Double]()
    var movementRangeSamples = [Double]()
    var meditationLog = [Bool]()
    var heart_rate_query : HKAnchoredObjectQuery?
    
    private var sampleTimer: Timer?
    private var notifyTimer: Timer?
    private var notifyTimerSeconds = 0
    
    private let healthStore = HKHealthStore()
    private let hkType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    private let hkworkT = HKObjectType.workoutType()
    private var samples = [HKCategorySample]()
    private let motionManager = CMMotionManager()
    
    var metadataWork = [String: Any]()
    
    static var options = Options()
    static var bluetoothManager: BluetoothManager?
    
    static var current: Session?
    
    override init()
    {
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
    
    func start()
    {
        if (!self.isRunning)
        {
            self.startDate = Date()
            
            requestAccessToHealthKit()
            
            motionManager.startDeviceMotionUpdates()
            
            healthStore.start(workoutSession!)
            
            WKInterfaceDevice.current().play(.start)
            
            createTimers()
            
            self.isRunning = true
            
            self.sendMessage(["watch": "start"], replyHandler: nil, errorHandler: nil)
            
        }
        else
        {
            print("called start on running session")
        }
    }
    
    func requestAccessToHealthKit() {
        
        Mixpanel.sharedInstance()?.track("watch_healthkit")
        
        if #available(watchOSApplicationExtension 5.0, *) {
            SettingsWatch.checkAuthorizationStatus { [weak self] success in
                if !success {
                    let healthKitTypes = SettingsWatch.getHealthKitTypes()
                    
                    self?.healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { success, error in
                        if(success)
                        {
                            Mixpanel.sharedInstance()?.track("watch_healthkit_success")
                        }
                         else
                        {
                            Mixpanel.sharedInstance()?.track("watch_healthkit_failed")
                        }
                    }
                }
            }
        }
    }
    
    func end(workoutEnd: @escaping (HKWorkout?)->()) {
        
        if !self.isRunning {
            print("called end on unrunning session")
            return
        }
        
        invalidate()
        
        motionManager.stopDeviceMotionUpdates()
        
        sample()
        
        WKInterfaceDevice.current().play(.stop)
        
        healthStore.end(workoutSession!)
        
        self.endDate = Date()
        
        var healthKitSamples: [HKSample] = []
        
        let energyUnit = HKUnit.smallCalorie()
        
        let energyValue = HKQuantity(unit: energyUnit, doubleValue: 0.0)
        
        let workout = HKWorkout(activityType: .mindAndBody, start: self.startDate!, end: self.endDate!, workoutEvents: nil, totalEnergyBurned: energyValue, totalDistance: nil, totalSwimmingStrokeCount: nil, device: nil, metadata: metadataWork)
        
        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        
        let mindfulSample = HKCategorySample(type:mindfulType, value: 0, start: self.startDate!, end: self.endDate!)
        
        healthKitSamples.append(mindfulSample)
        
        if(self.heartRateSamples.count > 2)
        {
            let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
            
            let hrvUnit = HKUnit(from: "ms")
            
            let quantityType = HKQuantity(unit: hrvUnit, doubleValue: self.heartSDNN)
            
            let hrvSample = HKQuantitySample(type: hrvType!, quantity: quantityType, start: self.startDate!, end: self.endDate!)
            
            healthKitSamples.append(hrvSample)
            
        }
        
        var allSamples : [HKSample] = healthKitSamples.map({$0})
        
        allSamples.append(workout)
        
        healthStore.save(allSamples)
        {
            success, error in
            
            self.sendMessage(["watch": "end"], replyHandler: nil, errorHandler: nil)
            
            guard error == nil else
            {
                print(error.debugDescription)
                workoutEnd(nil)
                return
            }
            
            self.healthStore.add(healthKitSamples, to: workout, completion:
            {
                    success, error in
                    
                    guard error == nil else {
                        print(error.debugDescription)
                        workoutEnd(nil)
                        return
                    }
                    
                    workoutEnd(workout)
                 
            })
            
        }
        
    }
    
    typealias HKQueryUpdateHandler = ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Swift.Void)
    
    private func process(samples: [HKQuantitySample])
    {
        samples.forEach { process(sample: $0) }
    }
    
    private func process(sample: HKQuantitySample)
    {
        self.heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/s"))
        heartRateSamples.append(self.heartRate)
        
        self.sample()
    }
    
    func createTimers() {
        
        notifyTimerSeconds = 0
        notifyTimer = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(Session.notify), userInfo: nil, repeats: true)
        
        
        if let bluetooth = Session.bluetoothManager
        {
            if(bluetooth.isConnected())
            {
                bluetooth.dataDelegate = self
                
                return
            }
        }
        
        let quantityType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        let datePredicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        
        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
        
        let updateHandler: HKQueryUpdateHandler =
        { query, samples, deletedObjects, queryAnchor, error in
            
            if let quantitySamples = samples as? [HKQuantitySample] {
                self.process(samples: quantitySamples)
            }
        }
        
        let heart_rate_query = HKAnchoredObjectQuery(type: quantityType,
                                                     predicate: queryPredicate,
                                                     anchor: nil,
                                                     limit: HKObjectQueryNoLimit,
                                                     resultsHandler: updateHandler)
        
        heart_rate_query.updateHandler = updateHandler
        
        self.heart_rate_query = heart_rate_query
        
        healthStore.execute(heart_rate_query)
        
    }
    
    func rrIntervalUpdated(_ rr: Int) {
        
        let bps = 1000 / Double(rr)
        
        if(bps != Double.infinity && bps != Double.nan && bps > 0.33 && bps < 3.67)
        {
            self.heartRate = Double(bps)
            
            heartRateSamples.append(self.heartRate)
            
            self.sample()
        }
    }
    
    func standardDeviation(_ arr : [Double]) -> Double
    {
        let rrIntervals = arr.map
        {
            (beat) -> Double in
            
            return 1000 / beat
        }
        
        let length = Double(rrIntervals.count)
        
        let avg = rrIntervals.reduce(0, +) / length
        
        let sumOfSquaredAvgDiff = rrIntervals.map
        {pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
        
        return sqrt(sumOfSquaredAvgDiff / length)
        
    }
    
    var haptic = WKHapticType.success
    var message = "Calibrating"
    
    //#todo(refactor): get the haptics and the meditation/feedback limits out of here
    @objc func notify(_ timer: Timer)
    {

        heartRateRangeSamples.append(self.heartRate)
        movementRangeSamples.append(self.motion)
        
        notifyTimerSeconds += 1
        
        if notifyTimerSeconds % 60 == 0
        {
            if(heartRateRangeSamples.count > 10)
            {
                let range = Int(((self.heartRateRangeSamples.max()! - self.heartRateRangeSamples.min()!) * 60.0).rounded())
                
                switch range
                {
                case 0...3:
                    haptic = WKHapticType.retry
                    message = "Breathe deeper"
                default:
                    haptic = WKHapticType.success
                    message = "Good work"
                }
            }
            
            if(self.isMotionFeedbackEnabled())
            {
                if(movementRangeSamples.count > 10 && notifyTimerSeconds > 60)
                {
                    let range = (self.movementRangeSamples.max()! - self.movementRangeSamples.min()!)
                    
                    if(range > 0.15)
                    {
                        haptic = WKHapticType.retry
                        message = "Stop moving"
                    }
                    else
                    {
                        haptic = WKHapticType.success
                        message = "Good work"
                    }
                }
            }
                        
            let iterations = (haptic == WKHapticType.retry) ?
                Int(Session.options.retryStrength) :
                Int(Session.options.hapticStrength)
                                    
            if iterations > 0
            {
                
                Thread.detachNewThread {
                        for _ in 1...iterations
                        {
                            DispatchQueue.main.async {
                                WKInterfaceDevice.current().play(self.haptic)
                            }
                            
                            Thread.sleep(forTimeInterval: 1)
                        }
                }
            }
            
            heartRateRangeSamples.removeAll()
            movementRangeSamples.removeAll()
            
            let isMeditating = (haptic == WKHapticType.success)
            
            if(isMeditating)
            {
                self.meditationLog.append(isMeditating)
            }
            else
            {
                self.meditationLog.removeAll()
            }
            
            let progress = "\(isMeditating)/\(self.meditationLog.count)".description
            
            NotificationCenter.default.post(name: .progress, object: progress)
            
            self.sendMessage(["progress" : progress], replyHandler: nil, errorHandler: nil)
            
        }
        
        if let date = self.startDate {
            self.delegate.sessionTick(startDate: date, message: message)
        }
        
    }
    
    func isMotionFeedbackEnabled() -> Bool
    {
        return true
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
        
        if(self.heartRateSamples.count > 2)
        {
            self.heartSDNN = standardDeviation(self.heartRateSamples)
        }
        
        var metadata: [String: Any] = [
            MetadataType.time.rawValue: Date().timeIntervalSince1970.description,
            MetadataType.now.rawValue: Date().description,
            MetadataType.motion.rawValue: motion.description,
            MetadataType.sdnn.rawValue: heartSDNN.description,
            MetadataType.heart.rawValue: heartRate.description,
            MetadataType.pitch.rawValue: self.rotation.pitch.description,
            MetadataType.roll.rawValue: self.rotation.roll.description,
            MetadataType.yaw.rawValue: self.rotation.yaw.description
        ]
        
        if SettingsWatch.appleUserID != nil
        {
            if(SettingsWatch.donations)
            {
                metadata["donated"] = SettingsWatch.donatedMinutes.description
            }
            
            if(SettingsWatch.progress)
            {
                metadata["progress"] = SettingsWatch.progressPosition
                metadata["appleID"] = SettingsWatch.email
            }
        }
                
        let empty = metadataWork.isEmpty ? "" : "/"
        
        for type in metadataTypeArray {
            metadataWork[type.rawValue] = ((metadataWork[type.rawValue] as? String) ?? "") + empty + (metadata[type.rawValue] as! String)
        }
        
        NotificationCenter.default.post(name: .sample, object: metadata)
        
        self.sendMessage(["sample" : metadata], replyHandler: nil, errorHandler: nil)
        
    }
    
    func invalidate()
    {
        notifyTimer!.invalidate()
        
        if let query = self.heart_rate_query
        {
            healthStore.stop(query)
        }
        
         else
         {
         if let bluetooth = Session.bluetoothManager
         {
         if(bluetooth.isConnected())
         {
         bluetooth.dataDelegate = nil
         
         return
         }
         }
         }
        
        self.isRunning = false
    }
}

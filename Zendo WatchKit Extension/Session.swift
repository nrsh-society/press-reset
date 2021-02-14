//
//  Session.swift
//  Zazen WatchKit Extension
//
//  Created by dmp on 12/29/17.
//  Copyright © 2017 zenbf. All rights reserved.
//
import Parse
import Smooth
import WatchKit
import HealthKit
import CoreMotion
import Foundation
import CoreFoundation
import WatchConnectivity

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
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()
    
    override init()
    {
        super.init()
        
        do {
           // workoutSession = try HKWorkoutSession(configuration: configuration)
            
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
            
            let configuration = HKWorkoutConfiguration()
            
            configuration.activityType = .other
            configuration.locationType = .unknown
        
            workoutSession = try? HKWorkoutSession(healthStore: ZBFHealthKit.healthStore, configuration: configuration)
            
            workoutSession?.startActivity(with: startDate)
            
            WKInterfaceDevice.current().play(.start)
            
            createTimers()
            
            self.isRunning = true
            
            let msg = ["watch": "start"]
            
            let onSuccess : (([String: Any]) -> Void)? =
            {
                replyHandler in
                
            }
            
            let onError : ((Error) -> Void)? = {
                
                error in
                
            }
            
            sessionDelegater.sendMessage(msg,
                                         replyHandler: onSuccess, errorHandler: onError)
            
        }
        else
        {
            print("called start on running session")
        }
    }
    
    func requestAccessToHealthKit() {
        if #available(watchOSApplicationExtension 5.0, *) {
            SettingsWatch.checkAuthorizationStatus { [weak self] success in
                if !success {
                    let healthKitTypes = SettingsWatch.getHealthKitTypes()
                    
                    self?.healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { success, error in
                        print("Successful HealthKit Authorization from Watch's extension Delegate")
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
        
        sample()
        
        motionManager.stopDeviceMotionUpdates()
        
        WKInterfaceDevice.current().play(.stop)
        
        self.endDate = Date()
        
        workoutSession?.stopActivity(with: self.endDate)
        
        workoutSession?.end()
        
        var healthKitSamples: [HKSample] = []
        
        let energyUnit = HKUnit.smallCalorie()
        
        let energyValue = HKQuantity(unit: energyUnit, doubleValue: 0.0)
        
        let workout = HKWorkout(activityType: .other, start: self.startDate!, end: self.endDate!, workoutEvents: nil, totalEnergyBurned: energyValue, totalDistance: nil, totalSwimmingStrokeCount: nil, device: nil, metadata: metadataWork)
        
        healthKitSamples.append(workout)
        
        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        
        let mindfulSample = HKCategorySample(type:mindfulType, value: 0, start: self.startDate!, end: self.endDate!, metadata: metadataWork)
        
        healthKitSamples.append(mindfulSample)
        
        if(self.heartRateSamples.count > 2)
        {
            let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
            
            let hrvUnit = HKUnit(from: "ms")
            
            let quantityType = HKQuantity(unit: hrvUnit, doubleValue: self.heartSDNN)
            
            let hrvSample = HKQuantitySample(type: hrvType!, quantity: quantityType, start: self.startDate!, end: self.endDate!)
            
            healthKitSamples.append(hrvSample)
            
        }
        
        sessionDelegater.sendMessage(["watch": "end"],
                                     replyHandler: nil,
                                     errorHandler: nil)
        
        healthStore.save(healthKitSamples)
        {
            success, error in
            
            guard error == nil else
            {
                print(error.debugDescription)
                
                workoutEnd(nil)
                
                return
            }
            
            workoutEnd(workout)
            
            self.sendMessage(["watch": "reload"],
            replyHandler:
            {
                (replyMessage) in
                
            },
            errorHandler:
            {
                error in
                
            })
        }
        
        invalidate()
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
    
    func createTimers()
    {
        notifyTimerSeconds = 0
        
        self.notifyTimer = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(Session.notify), userInfo: nil, repeats: true)
        
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
        let beatsAsFloat : Array<Float> = arr.map
        {
            Float(1000 / $0)
        }
        
        let smoothBeats = CubicInterpolator(points:
            CubicInterpolator(points: beatsAsFloat, tension: 0.1).resample(interval: 3)
                          , tension: 0.1).resample(interval: 0.25).map { $0 }
        
        let smoothBeatsAsDouble = smoothBeats.map
        {
                Double($0)
        }
        
        let length = Double(smoothBeatsAsDouble.count)
        
        let avg = smoothBeatsAsDouble.reduce(0, +) / length
        
        let sumOfSquaredAvgDiff = smoothBeatsAsDouble.map
        {pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
        
        return sqrt(sumOfSquaredAvgDiff / length)
        
    }
    
    var haptic = WKHapticType.success
    var message = "Calibrating"
    
    // i am
    //  called every 1 sec.
    //  add the heartRate + motion data to a range/window
    //  look at the window every 1 min and notify listeners if the person is meditating
    //  listeners are the haptic/sound interface on the watch + zendo server/services
    //  this clearly needs to be refactored.
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
            
            self.meditationLog.append(isMeditating)
            
            let progress = "\(isMeditating)/\(self.meditationLog.count)".description
            
            if(SettingsWatch.donations)
            {
                SettingsWatch.donatedMinutes += 1
                
                PFCloud.callFunction(inBackground: "donate",
                                     withParameters: ["id": SettingsWatch.appleUserID as Any, "donatedMinutes": SettingsWatch.donatedMinutes])
                {
                    (response, error) in

                    if let error = error
                    {
                        print(error)
                    }
                }
                
            }
            
            if(SettingsWatch.progress)
            {
                PFCloud.callFunction(inBackground: "rank",
                                     withParameters: ["id": SettingsWatch.appleUserID as Any, "donatedMinutes": SettingsWatch.donatedMinutes ])
                {
                    (response, error) in

                    if let error = error
                    {
                        print(error)
                                        
                        SettingsWatch.progressPosition = "-/-"
                    }
                    else
                    {
                        if let rank = response as? String
                        {
                            SettingsWatch.progressPosition = rank
                        }
                    }
                }
            }
            
            let msg = ["progress" : progress]
                
            sessionDelegater.sendMessage(msg,
                                         replyHandler:
                                            {
                                                message in
                
                                                print(message.debugDescription)
                                            },
                                         errorHandler:
                                            {
                                                error in
                
                                                print(error)
                                            })
        }
        
        if let date = self.startDate
        {
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
        
        if let appleUserUUID = SettingsWatch.appleUserID
        {
            if(SettingsWatch.donations)
            {
                metadata["donated"] = SettingsWatch.donatedMinutes.description
            }
            
            if(SettingsWatch.progress)
            {
                metadata["progress"] = SettingsWatch.progressPosition
                metadata["appleID"] = SettingsWatch.fullName
            }
        }
        
        sessionDelegater.sendMessage(["sample" : metadata],
                                     
            replyHandler:
            {
                (message) in
                
                print(message.debugDescription)
            },
            
            errorHandler:
            {
                (error) in
                    print(error)
            })
        
        NotificationCenter.default.post(name: .sample, object: metadata)
        
        let empty = metadataWork.isEmpty ? "" : "/"
        
        for type in metadataTypeArray {
            metadataWork[type.rawValue] = ((metadataWork[type.rawValue] as? String) ?? "") + empty + (metadata[type.rawValue] as! String)
        }
        
        
        #if DEBUG //using this for a live heartrate monitor
            let meditation = PFObject(className:"Meditation")
            meditation["start"] = self.startDate
            meditation["hr"] = self.heartRate
            meditation["hrv"] = self.heartSDNN
            meditation["now"] = Date()
            
            meditation.saveInBackground { (succeeded, error)  in
                if (succeeded) {
                    // The object has been saved.
                } else {
                    // There was a problem, check error.description
                }
            }
        #endif
        
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

//
//  Cloud.swift
//  zendoArena
//
//  Created by Douglas Purdy on 2/12/19.
//  Copyright © 2019 Zendo Tools. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FBSDKCoreKit
import Mixpanel
import FirebaseStorage
import FacebookCore
import AppTrackingTransparency

class Player
{
    var id : String
    var email : String?
    var duration : Int = 0
    var samples = [Double]()
    var startDate = Date()

    init(id: String)
    {
        self.id = id
    }

    func getProfileUrl() -> String
    {
        return "\(self.id)"
    }

    func getMeditativeState() -> Bool
    {
        var retval = false

        if (self.samples.count > 2)
        {
            let min = self.samples.min()
            let max = self.samples.max()

            let range = max! - min!

            if range > 2
            {
                retval = true
            }
        }

        return retval
    }

    func getProgress() -> String
    {
        var progress = "true/0"

        let startDate = self.startDate

        let mins = abs(startDate.minutes(from: Date()))

        if(mins > 0)
        {
            progress = "\(self.getMeditativeState())/\(mins)"
        }

        return progress
    }

    func getUpdate() -> [String : String]
    {
        return [ "progress" : self.getProgress()]
    }

    func getHRV() -> Double
    {
        return self.standardDeviation(self.samples)
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

}

class Cloud
{
    static var enabled = false
    
    static func createPlayer(email: String, image: UIImage )
    {
        var data = Data()
        data = UIImageJPEGRepresentation(image, 0.8)!
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let key = email.replacingOccurrences(of: ".", with: "_")
        
        let profileRef = storageRef.child( key + ".jpg")
        
        _ = profileRef.putData(data, metadata: nil)
        {
            (metadata, error) in
            
            guard let metadata = metadata else
            {
                return
            }
            
            profileRef.downloadURL
            {
                (url, error) in
                
                guard let downloadURL = url else
                {
                    return
                }
                
                print(downloadURL)
            }
        }
    }
        
    static func updatePlayer(email: String, update: Any?)
    {
        let database = Database.database().reference()
        let players = database.child("players")
        
        let key_string = email.replacingOccurrences(of: ".", with: "_")
        
        let key = players.child(key_string)
        
        key.setValue(update)
        {
            (error, ref) in
            
            if let error = error
            {
                print("Data could not be saved: \(error).")
                
                return
            }
            
        }

    }
    
    static func renamePlayer( _ currentEmail: String, _ newEmail: String)
    {
        
        let database = Database.database().reference()
        let players = database.child("players")
        
        let key_string = currentEmail.replacingOccurrences(of: ".", with: "_")
        let new_key_string = newEmail.replacingOccurrences(of: ".", with: "_")
        
        let key = players.child(key_string)
        
    }
    
    static func updatePlayer(email: String, sample: [String : Any] )
    {
        let database = Database.database().reference()
        let players = database.child("players")
        
        let key = players.child(email.replacingOccurrences(of: ".", with: "_"))
        
        key.setValue(sample)
        {
            (error, ref) in
            
            if let error = error
            {
                print("Data could not be saved: \(error).")
            }
        }
    }
    
    static func removePlayer(email: String)
    {
        let database = Database.database().reference()
        let players = database.child("players")
        
        let key = players.child(email.replacingOccurrences(of: ".", with: "_"))
        
        key.removeValue()
    }
    
    static func removePlayers()
    {
        let database = Database.database().reference()
        
        let players = database.child("players")
        
        players.removeValue()
        
    }

    typealias PlayersChangedHandler = (_ player : [String: Int], _ error: Error? ) -> Void
    
    static func registerPlayersChangedHandler(handler: @escaping PlayersChangedHandler) -> DatabaseHandle?
    {
        if(!enabled)
        {
            print ("Cloud disabled")
            return nil
        }
        
        let database = Database.database().reference()
        
        let sample = database.child("players")
        
        let refHandle = sample.observe(DataEventType.value)
        {
            (snapshot) in
            
            if let value = snapshot.value as? [String : Int]
            {
                handler(value, nil)
            }
        }
        
        refHandles.append(refHandle)
        
        return refHandle
    }
    
    static func updateSample(email: String, content: String, sample: [String : Any])
    {
        
        let value = ["data" : sample,
            "updated" : Date().description,
            "content" : content,
            "email" : email] as [String : Any]
     
        let database = Database.database().reference()
     
        let sample = database.child("samples")
     
        let key = sample.child(email.replacingOccurrences(of: ".", with: "_"))
     
        key.setValue(value)
        {
            (error, ref) in
     
            if let error = error
            {
                print("Data could not be saved: \(error).")
            }
        }
     }
    
    static func updateProgress(email: String, content: String, progress: [String])
    {
        
        let value = ["data" : progress,
                     "updated" : Date().timeIntervalSince1970.description,
                     "content" : content,
                     "email" : email] as [String : Any]
        
        let database = Database.database().reference()
        
        let sample = database.child("progress")
        
        let key = sample.child(email.replacingOccurrences(of: ".", with: "_"))
        
        key.setValue(value)
        {
            (error, ref) in
            
            if let error = error
            {
                print("Data could not be saved: \(error).")
            }
        }
    }

    static func enable(_ application: UIApplication, _ options : [UIApplicationLaunchOptionsKey : Any]?)
    {
        if #available(iOS 14, *) {
            
            ATTrackingManager.requestTrackingAuthorization { status in
                
                if (status == .authorized)
                {
                    ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: options)
                }
            }
        }
       
        FirebaseApp.configure()
    
        Mixpanel.initialize(token: "73167d0429d8da0c05c6707e832cbb46")
        
        BuddyBuildSDK.setup()
        
        CommunityDataLoader.load()
        
        self.enabled = true
    }
    
    static func unregisterChangeHandlers()
    {
        refHandles.forEach(
        {
            entry in
            
            let database = Database.database().reference()
            
            database.removeObserver(withHandle: entry)
            
        })
    }
    
    typealias SamplesChangedHandler = (_ samples : [String : [String : AnyObject]], _ error: Error? ) -> Void

    static var refHandles : [DatabaseHandle] = []
    
    static func registerSamplesChangedHandler(handler: @escaping SamplesChangedHandler) -> DatabaseHandle?
    {
        if(!enabled)
        {
            print ("Cloud disabled")
            return nil
        }
        
        let database = Database.database().reference()
        
        let sample = database.child("samples")
        
        let refHandle = sample.observe(DataEventType.value)
        {
            (snapshot) in
            
            if let samples = snapshot.value as? [String : [String : AnyObject]]
            {
                handler(samples, nil)
            }
        }
        
        refHandles.append(refHandle)
        
        return refHandle
    }
    
    typealias ProgressChangedHandler = (_ progress : [String : [String : AnyObject]], _ error: Error? ) -> Void
    
    static func registerProgressChangedHandler(handler: @escaping ProgressChangedHandler) -> DatabaseHandle?
    {
        if(!enabled)
        {
            print ("Cloud disabled")
            return nil
        }
        
        let database = Database.database().reference()
        
        let sample = database.child("progress")
        
        let refHandle = sample.observe(DataEventType.value)
        {
            (snapshot) in
            
            if let samples = snapshot.value as? [String : [String : AnyObject]]
            {
                handler(samples, nil)
            }
        }
        
        refHandles.append(refHandle)
        
        return refHandle
    }
    
}

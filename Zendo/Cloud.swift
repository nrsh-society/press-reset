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
        
        let uploadTask = profileRef.putData(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            // You can also access to download URL after upload.
            profileRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    return
                }
                
                print(downloadURL)
            }
        }
    }
    
    struct Player
    {
        var email : String
        var progress : [String]
        var sample : [String : Any]
    }
    
    static func updatePlayer(email: String, progress: [String]?, sample: [String: Any]?)
    {

        let player = Player(email: email, progress: progress ?? [String](), sample: sample ?? [String: Any]())
        
        let database = Database.database().reference()
        let players = database.child("players")
        
        let key_string = email.replacingOccurrences(of: ".", with: "_")
        
        let key = players.child(key_string)
        
        key.setValue(player)
        {
            (error, ref) in
            
            if let error = error
            {
                print("Data could not be saved: \(error).")
                
                return
            }
            
        }

    }

    static func updatePlayer(email: String, mins: Int )
    {
        let database = Database.database().reference()
        let players = database.child("players")
        
        let key = players.child(email.replacingOccurrences(of: ".", with: "_"))
        
        key.setValue(mins)
        {
            (error, ref) in
            
            if let error = error
            {
                print("Data could not be saved: \(error).")
            }
        }
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
        FirebaseApp.configure()
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: options)
        
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

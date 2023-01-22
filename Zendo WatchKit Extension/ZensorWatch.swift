//
//  ZensorWatch.swift
//
//  Created by Douglas Purdy on 1/24/20.
//  Copyright © 2020 Zendo Tools. All rights reserved.
//
import Parse
import Foundation

public class Zensor : Identifiable, ObservableObject
{
    
    public var id : String
    public var name : String
    var startDate = Date()
    
    @Published public var hrv = 0.0
    @Published public var hr = 0.0
    @Published public var duration : String = "0"
    @Published public var progress : String = "true/0"
    @Published public var isMeditating : Bool = false
    @Published public var isInBreath : Bool = false
    @Published public var isOutBreath : Bool = false
    @Published public var level : Int = 0
    @Published public var samples = [Double]()
    
    init(id: String, name: String, hr: Double) {
        
        self.id = id
        self.name = name
        self.hr = hr
    }
    
    func update(hr: Double) {
        
        self.samples.append(hr)
        
        self.hr = hr.rounded()
         
        self.duration = self.getDuration().description
        
        self.isInBreath = self.getInBreath()
                   
        self.isOutBreath = self.getOutBreath()
        
        self.hrv = self.getHRV()

        if (self.samples.count > 9 && self.samples.count % 10 == 0)
        {
            self.isMeditating = getMeditativeState()
            
            self.level = getLevel()
                        
            //self.progress = self.getProgress()
            
            //self.publish()
        }
    }
    
    func update(progress: String)
    {
        self.progress = progress
        self.publish()
    }
    
    
    func getInBreath() -> Bool
    {
        var retval = false
        
        if(self.samples.count > 9)
        {
            let lastSamples = Array(self.samples.suffix(3))
            
            if(lastSamples.count == 3)
            {
                //is the heartrate sloping up?
                retval = lastSamples[0] + lastSamples[1] < lastSamples[1] + lastSamples[2]
            }
        }
        
        return retval
    }
    
    func getOutBreath() -> Bool
    {
        var retval = false
        
        if(self.samples.count > 10)
        {
            let lastSamples = Array(self.samples.suffix(3))
            
            if(lastSamples.count == 3)
            {
                //is the heartrate sloping down?
                retval = lastSamples[2] + lastSamples[1] < lastSamples[1] + lastSamples[0]
            }
        }
        
        return retval
    }
    
    func getLevel() -> Int {
        
        var retval = 0
        
        if(self.isMeditating)
        {
            retval = self.level + 1
        }
        
        return retval
    }
    
    func getMeditativeState() -> Bool
    {
        var retval = false
        
        if (self.samples.count > 10)
        {
            let min = self.samples.suffix(10).min()
            let max = self.samples.suffix(10).max()
            
            let range = max! - min!
            
            if range > 3.0
            {
                retval = true
            }
            
        }
        
        return retval
    }
    
    func getDuration() -> Int
    {
        let startDate = self.startDate
        
        let seconds = abs(startDate.seconds(from: Date()))
        
        return seconds
    }
    
    func getProgress() -> String
    {
        progress = "\(self.isMeditating)/\(self.level)"
    
        return progress
    }
    
    func getUpdate() -> [String : Any]
    {
        return ["player": self.id, "duration": self.duration, "hr" : self.hr, "hrv" : self.hrv, "meditating": self.isMeditating , "level": self.level, "game_progress" : self.progress]
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
            
            return ((1000 * 60) / beat)
        }
        
        let length = Double(rrIntervals.count)
        
        let avg = rrIntervals.reduce(0, +) / length
        
        let sumOfSquaredAvgDiff = rrIntervals.map
        {pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
        
        return sqrt(sumOfSquaredAvgDiff / length)
        
    }
    
    func publish()
    {
        /*
        if let user = PFUser.current() {
            
            user.setValuesForKeys(self.getUpdate())
            
            user.saveInBackground()
            
        }*/
        
        let meditation = PFObject(className:"Meditation")
     
        meditation.setValuesForKeys(self.getUpdate())
        
        meditation.saveInBackground {
            
            (succeeded, error)  in
            
            if (succeeded) {
                // The object has been saved.
            } else {
                // There was a problem, check error.description
            }
        }
    }
    
    func reset()
    {
        
        
    }
}

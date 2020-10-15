//
//  PFUser+Settings.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 10/6/20.
//  Copyright © 2020 zenbf. All rights reserved.
//
import Parse
import Foundation

extension PFUser
{
    var migratedToParse: Bool
    {
        set
        {
            PFUser.current()?["migratedToParseKey"] = newValue
        }
        get
        {
            if let migratedToParse = (PFUser.current()?["migratedToParseKey"]) as? Bool
            {
                return migratedToParse
            }
            else
            {
                return false
            }
        }
    }
    
    var donations: Bool
    {
        set
        {
            PFUser.current()?["donations"] = newValue
        }
        get
        {
            if let donations = (PFUser.current()?["donations"]) as? Bool
            {
                return donations
            }
            else
            {
                return false
            }
        }
    }
    
    var donatedMinutes: Int
    {
        set
        {
            PFUser.current()?["donatedMinutes"] = newValue
        }
        get
        {
            if let donatedMinutes = (PFUser.current()?["donatedMinutes"]) as? Int
            {
                return donatedMinutes
            }
            else
            {
                return 0
            }
        }
    }
        
    var progress: Bool
    {
        set
        {
            PFUser.current()?["progress"] = newValue
        }
        get
        {
            if let progress = (PFUser.current()?["progress"]) as? Bool
            {
                return progress
            }
            else
            {
                return false
            }
        }
    }
    
    var progressPosition: String
    {
        set
        {
            PFUser.current()?["progressPosition"] = newValue
        }
        get
        {
            if let progressPosition = (PFUser.current()?["progressPosition"]) as? String
            {
                return progressPosition
            }
            else
            {
                return "-/-"
            }
        }
    }
    
    var successFeedbackLevel: Int
    {
        set
        {
            PFUser.current()?["successFeedbackStrength"] = newValue
        }
        get
        {
            if let hapticStrength = (PFUser.current()?["successFeedbackLevel"]) as? Int
            {
                return hapticStrength
            }
            else
            {
                return 1
            }
        }
    }
    
    var retryFeedbackLevel: Int
    {
        set
        {
            PFUser.current()?["retryFeedbackLevel"] = newValue
        }
        get
        {
            if let hapticStrength = (PFUser.current()?["retryFeedbackLevel"]) as? Int
            {
                return hapticStrength
            }
            else
            {
                return 1
            }
        }
    }
    
    
    func track(_ name: String)
    {
        PFAnalytics.trackEvent(name)
    }
}

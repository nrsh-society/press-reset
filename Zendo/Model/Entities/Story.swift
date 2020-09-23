//
//  Storie.swift
//  Zendo
//
//  Created by Anton Pavlov on 23/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation
import SwiftyJSON
import Cache


class Story: Codable {
    
    var title: String!
    var thumbnailUrl: String?
    var type: String?
    var sponsorPayID: String?
    var causePayID: String?
    var sponsorKey: String?
    var backgroundOpacity: String?
    var cameraOpacity: String?
    var creatorPayID: String?
    var introURL: String?
    var outroMessage: String?
    var enableBoard: Bool! //= false
    var enableProgress: Bool! //= false
    var enableRecord: Bool! //= false
    var enableStats: Bool! = true
    
    var content = [Content]()
    
    public init(_ json: JSON) {
        
        if let enableBoard = json["enableBoard"].bool {
            self.enableBoard = enableBoard
        }
        
        if let enableProgress = json["enableProgress"].bool {
            self.enableProgress = enableProgress
        }
        
        if let enableRecord = json["enableRecord"].bool {
            self.enableRecord = enableRecord
        }
        
        if let enableStats = json["enableStats"].bool {
            self.enableStats = enableStats
        }
        
        if let title = json["title"].string {
            self.title = title
        }
        
        if let thumbnailUrl = json["thumbnailUrl"].string {
            self.thumbnailUrl = thumbnailUrl
        }
        
        if let type = json["type"].string {
            self.type = type
        }
        
        if let sponsorPayID = json["sponsorPayID"].string {
            self.sponsorPayID = sponsorPayID
        }
        
        if let causePayID = json["causePayID"].string {
            self.causePayID = causePayID
        }
        
        if let sponsorKey = json["sponsorKey"].string {
            self.sponsorKey = sponsorKey
        }
        
        if let backgroundOpacity = json["backgroundOpacity"].string {
            self.backgroundOpacity = backgroundOpacity
        }
        
        if let cameraOpacity = json["cameraOpacity"].string {
            self.cameraOpacity = cameraOpacity
        }
        
        if let creatorPayID = json["creatorPayID"].string {
            self.creatorPayID = creatorPayID
        }
        
        if let introURL = json["introUrl"].string {
            self.introURL = introURL
        }
        
        if let outroMessage = json["outroMessage"].string {
            self.outroMessage = outroMessage
        }
        
        content = json["content"].toContents
        
    }
    
}


extension JSON {
    var toStories: [Story] {
        var res = [Story]()
        guard let ar = self.array else {return res}
        for c in ar {
            res.append(Story(c))
        }
        return res
    }
}

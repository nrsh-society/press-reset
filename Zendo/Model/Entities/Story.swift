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
    var creatorPaymentAddress: String?
    var beneficiaryPaymentAddress: String?

    var content = [Content]()
    
    public init(_ json: JSON) {
        
        if let title = json["title"].string {
            self.title = title
        }
        
        if let thumbnailUrl = json["thumbnailUrl"].string {
            self.thumbnailUrl = thumbnailUrl
        }
        
        if let type = json["type"].string {
            self.type = type
        }
        
        if let creatorPaymentAddress = json["creatorPaymentAddress"].string {
            self.creatorPaymentAddress = creatorPaymentAddress
        }
        
        if let beneficiaryPaymentAddress = json["beneficiaryPaymentAddress"].string {
            self.beneficiaryPaymentAddress = beneficiaryPaymentAddress
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

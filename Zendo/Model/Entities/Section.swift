//
//  Sections.swift
//  Zendo
//
//  Created by Anton Pavlov on 23/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation
import SwiftyJSON
import Cache


class Section: Codable {
    
    var name: String!
    var thumbnailUrl: String?
    var stories = [Story]()
    
    public init(_ json: JSON)  {
        
        if let name = json["name"].string {
            self.name = name
        }
        
        if let thumbnailUrl = json["thumbnailUrl"].string {
            self.thumbnailUrl = thumbnailUrl
        }
        
        stories = json["stories"].toStories
    }
    
}

extension JSON {
    var toSections: [Section] {
        var res = [Section]()
        guard let ar = self.array else {return res}
        for c in ar {
            res.append(Section(c))
        }
        return res
    }
}

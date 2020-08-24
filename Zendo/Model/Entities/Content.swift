//
//  Content.swift
//  Zendo
//
//  Created by Anton Pavlov on 23/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation
import SwiftyJSON
import Cache


class Content: Codable {
    
    var thumbnailUrl: String!
    var stream: String?
    var download: String?
    
    public init(_ json: JSON) {
        
        if let thumbnailUrl = json["thumbnailUrl"].string {
            self.thumbnailUrl = thumbnailUrl
        }
        
        if let stream = json["stream"].string {
            self.stream = stream
        }

        if let download = json["download"].string {
            self.download = download
        }
        
    }
    
}


extension JSON {
    var toContents: [Content] {
        var res = [Content]()
        guard let ar = self.array else {return res}
        for c in ar {
            res.append(Content(c))
        }
        return res
    }
}

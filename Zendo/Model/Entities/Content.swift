//
//  Content.swift
//  Zendo
//
//  Created by Anton Pavlov on 23/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation
import SwiftyJSON

class Content {
    
    var thumbnailUrl: String!
    var content: String!
    
    public init(_ json: JSON)  {
        
        if let thumbnailUrl = json["thumbnailUrl"].string{
            self.thumbnailUrl = thumbnailUrl
        }
        
        if let content = json["content"].string{
            self.content = content
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

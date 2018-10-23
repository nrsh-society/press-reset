//
//  Discover.swift
//  Zendo
//
//  Created by Anton Pavlov on 23/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//


import Foundation
import SwiftyJSON


public class Discover {
    
    var name: String!
    var description: String!
    var sections = [Section]()
    
    public init(_ json: JSON)  {
        
        if let name = json["name"].string{
            self.name = name
        }
        
        if let description = json["description"].string{
            self.description = description
        }
        
        sections = json["sections"].toSections
        
    }
}

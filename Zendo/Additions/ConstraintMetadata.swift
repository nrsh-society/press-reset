//
//  ConstraintMetadata.swift
//  Zendo
//
//  Created by Anton Pavlov on 16/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation

enum MetadataType: String {
    case time = "time"
    case now = "now"
    case motion = "motion"
    case sdnn = "sdnn"
    case heart = "heart"
    case pitch = "pitch"
    case roll = "roll"
    case yaw = "yaw"
}

let metadataTypeArray: [MetadataType] = [.time, .now, .motion, .sdnn, .heart, .pitch, .roll, .yaw]

let metadataTypeArraySmall: [MetadataType] = [.time, .sdnn, .heart]

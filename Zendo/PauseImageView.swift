//
//  PauseImageView.swift
//  Zendo
//
//  Created by Anton Pavlov on 28/11/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

class PauseImageView: UIImageView {
    
    var playerStatus = PlayerStatus.pause {
        didSet {
            image = playerStatus.image
        }
    }
    
}

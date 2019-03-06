//
//  SKSpriteNode.swift
//  Zendo
//
//  Created by Anton Pavlov on 06/03/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import UIKit
import SpriteKit


extension SKSpriteNode {
    func addTo(parent: SKNode?, withRadius: CGFloat) {
        guard parent != nil else { return }
        guard  withRadius>0.0 else {
            parent!.addChild(self)
            return
        }
        let radiusShape = SKShapeNode.init(rect: CGRect.init(origin: CGPoint.zero, size: size), cornerRadius: withRadius)
        radiusShape.position = CGPoint.zero
        radiusShape.lineWidth = 2.0
        radiusShape.fillColor = UIColor.red
        radiusShape.strokeColor = UIColor.red
        radiusShape.zPosition = 2
        radiusShape.position = CGPoint.zero
        let cropNode = SKCropNode()
        cropNode.position = self.position
        cropNode.zPosition = 3
        cropNode.addChild(self)
        cropNode.maskNode = radiusShape
        parent!.addChild(cropNode)
    }
}

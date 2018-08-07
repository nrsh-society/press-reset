//
//  ZenInfoView.swift
//  Zendo
//
//  Created by Anton Pavlov on 07/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

enum ZenInfoViewType: String {
    case hrvAverage = "hrv average"
    case totalMins = "total mins"
    
    var image: UIImage {
        switch self {
        case .hrvAverage: return UIImage(named: "hrv")!
        case .totalMins: return UIImage(named: "time")!
        }
    }
}

@IBDesignable class ZenInfoView: UIView {
    
    @IBOutlet weak var topTitle: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var image: UIImageView!
    
    var zenInfoViewType: ZenInfoViewType?

    override func layoutSubviews() {
        super.layoutSubviews()
        
        setShadowView()
        
        if let type = zenInfoViewType {
            image.image = type.image
            topTitle.text = type.rawValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }
}



//
//  ZenInfoView.swift
//  Zendo
//
//  Created by Anton Pavlov on 07/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

enum ZenInfoViewType: String {
    case hrvAverage = "hrv average"
    case totalMins = "total mins"
    case averageMins = "average mins"
    
    var image: UIImage {
        switch self {
        case .hrvAverage: return UIImage(named: "hrv")!
        case .totalMins: return UIImage(named: "time")!
        case .averageMins: return UIImage(named: "time")!
        }
    }
}

@IBDesignable class ZenInfoView: UIView {
    
    @IBOutlet weak var topTitle: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var dots: NVActivityIndicatorView!
    
    var zenInfoViewType: ZenInfoViewType?
    
    func setTitle(_ text: String) {
        if text.isEmpty {
            title.isHidden = true
            dots.isHidden = false
            dots.startAnimating()
        } else {
            dots.stopAnimating()
            title.text = text
            title.isHidden = false
            dots.isHidden = true
        }
    }

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



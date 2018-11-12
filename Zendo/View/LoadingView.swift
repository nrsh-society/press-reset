//
//  LoadingView.swift
//  Zendo
//
//  Created by Anton Pavlov on 18/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit


class LoadingView: UIView {
    
    @IBOutlet weak var widthLoadView: NSLayoutConstraint!
    @IBOutlet weak var loadView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        loadView.clipsToBounds = true
        loadView.layoutIfNeeded()
    }
    
    func setStart() {
        DispatchQueue.main.async {
              self.widthLoadView.constant = 0
        }
    }
    
    func setCurent(_ alpha: Double) {
        DispatchQueue.main.async {
            if !alpha.isNaN && !alpha.isInfinite {
                self.widthLoadView.constant = self.bounds.width * CGFloat(alpha)
                self.loadView.setNeedsUpdateConstraints()

                UIView.animate(withDuration: 1.0) {
                    self.loadView.layoutIfNeeded()
                }
            }
        }
    }
    
    func setEnd() {
        DispatchQueue.main.async {
            self.widthLoadView.constant = self.bounds.width
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

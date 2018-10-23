//
//  LoadingView.swift
//  Zendo
//
//  Created by Anton Pavlov on 18/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

class LoadingView: UIView {
    
    @IBOutlet weak var loadView: UIView!
//    @IBOutlet weak var loadViewWidth: NSLayoutConstraint!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        loadView.clipsToBounds = true
    }
    
    func setStart() {
        DispatchQueue.main.async {
//            self.loadViewWidth.constant = 1
            
              self.loadView.frame.size.width = 0
        }
    }
    
    func setCurent(_ alpha: Double) {
        DispatchQueue.main.async {
            if !alpha.isNaN && !alpha.isInfinite {
                UIView.animate(withDuration: 1.3) {
                    self.loadView.frame.size.width = self.bounds.width * CGFloat(alpha)
                }
            }
            
        }
    }
    
    func setEnd() {
        DispatchQueue.main.async {
            self.loadView.frame.size.width = self.bounds.width
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

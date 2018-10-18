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
            
//            self.loadViewWidth.constant = self.bounds.width * CGFloat(alpha)
            
            if !alpha.isNaN {
                UIView.animate(withDuration: 1) {
                    self.loadView.frame.size.width = self.bounds.width * CGFloat(alpha)
                    //                self.layoutIfNeeded()
                }
            }
                       
        }
    }
    
    func setEnd() {
        DispatchQueue.main.async {
//            self.loadViewWidth.constant = self.bounds.width
            
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

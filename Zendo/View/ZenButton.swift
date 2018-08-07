//
//  ZenButton.swift
//  Zendo
//
//  Created by Anton Pavlov on 07/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

@IBDesignable class ZenButton: UIView {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var bottomView: UIView!
    var action: (()->())?
    
    @IBInspectable public var titleButton: String = "" {
        didSet {
            title.text = titleButton
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.addTarget(self, action: #selector(touchDown), for: .touchDown)
        button.addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
        button.addTarget(self, action: #selector(touchUpOutside), for: .touchUpOutside)
    }
    
    func setView(alpha: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.title.alpha = alpha
            self.bottomView.alpha = alpha
        }
    }
    
    @objc func touchDown(_ sender: UIButton) {
        setView(alpha: 0.5)
    }
    
    @objc func touchUpInside(_ sender: UIButton) {
        setView(alpha: 1.0)
        action?()
    }
    
    @objc func touchUpOutside(_ sender: UIButton) {
        setView(alpha: 1.0)
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

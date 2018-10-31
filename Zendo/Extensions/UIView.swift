//
//  UIView.swift
//  Zendo
//
//  Created by Anton Pavlov on 02/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

extension UIView {
    
    func setShadowView() {
        
        layer.cornerRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowColor = UIColor(red:0.73, green:0.73, blue:0.73, alpha:0.2).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 10
    }
    
    func addSubviews(_ views: UIView...){
        views.forEach(addSubview)
    }
}

extension UIView {
    
    func fillSuperview() {
        anchor(top: superview?.topAnchor, bottom: superview?.bottomAnchor, leading: superview?.leadingAnchor, trailing: superview?.trailingAnchor)
    }
    
    func edges(_ value: CGFloat = 0.0, to item: UIView? = nil){
        anchor(top: item?.topAnchor ?? superview?.topAnchor, bottom: item?.bottomAnchor ?? superview?.bottomAnchor, leading: item?.leadingAnchor ?? superview?.leadingAnchor, trailing: item?.trailingAnchor ?? superview?.trailingAnchor, padding: .init(top: value, left: value, bottom: value, right: value))
    }
    
    func anchor(top: NSLayoutYAxisAnchor?, bottom: NSLayoutYAxisAnchor?, leading: NSLayoutXAxisAnchor?, trailing: NSLayoutXAxisAnchor?, padding: UIEdgeInsets = .zero, size: CGSize = .zero){
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top{
            topAnchor.constraint(equalTo: top, constant: padding.top).isActive = true
        }
        
        if let bottom = bottom{
            bottomAnchor.constraint(equalTo: bottom, constant: -padding.bottom).isActive = true
        }
        
        if let leading = leading{
            leadingAnchor.constraint(equalTo: leading, constant: padding.left).isActive = true
        }
        
        if let trailing = trailing{
            trailingAnchor.constraint(equalTo: trailing, constant: -padding.right).isActive = true
        }
        
        if size.width != 0{
            widthAnchor.constraint(equalToConstant: size.width).isActive = true
        }
        
        if size.height != 0{
            heightAnchor.constraint(equalToConstant: size.height).isActive = true
        }
        
    }
    
    func anchorSize(to view: UIView){
        widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }
    
    func width(_ value: CGFloat){
        widthAnchor.constraint(equalToConstant: value).isActive = true
    }
    
    func height(_ value: CGFloat){
        heightAnchor.constraint(equalToConstant: value).isActive = true
    }
}

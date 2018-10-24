//
//  UIImageView.swift
//  Zendo
//
//  Created by Anton Pavlov on 23/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func imageFromUrl(urlString: String, completed: ((UIImage?)->())? = nil) {
        if let url = URL(string: urlString) {
            
            URLSession.shared.dataTask(with: url) { data, response, error -> Void in
                if let imageData = data {
                    DispatchQueue.main.async {
                        let i = UIImage(data: imageData)
                        completed?(i)
                        self.image = i
                    }
                }
                }.resume()
            
        }
    }
    
}

extension UIImage {
    
    static func imageFromUrl(urlString: String, completed: @escaping ((UIImage)->()) ) {
        if let url = URL(string: urlString) {
            
            URLSession.shared.dataTask(with: url) { data, response, error -> Void in
                if let imageData = data, let image = UIImage(data: imageData) {
                    completed(image)
                }
                }.resume()
            
        }
    }
    
}

extension UIView {
    
    func addBackground(image: UIImage) {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        
        let imageViewBackground = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: width, height: height))
        imageViewBackground.image = image
        
        imageViewBackground.contentMode = UIViewContentMode.scaleAspectFill
        
        //        self.addSubview(imageViewBackground)
        //        self.sendSubview(toBack: imageViewBackground)
        
        layer.insertSublayer(imageViewBackground.layer, at: 0)
    }
    
}

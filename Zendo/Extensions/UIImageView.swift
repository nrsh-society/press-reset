//
//  UIImageView.swift
//  Zendo
//
//  Created by Anton Pavlov on 23/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func imageFromUrl(urlString: String) {
        if let url = URL(string: urlString) {
            
            URLSession.shared.dataTask(with: url) { data, response, error -> Void in
                if let imageData = data {
                    DispatchQueue.main.async {
                        self.image = UIImage(data: imageData)
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

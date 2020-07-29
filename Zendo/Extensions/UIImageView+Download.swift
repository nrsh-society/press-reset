//
//  UIImageView+Download.swift
//  
//
//  Created by Anton Pavlov on 23/11/2018.
//

import UIKit
import SDWebImage


extension UIImageView {
    
    func setImage(from url: URL?, indexPath: IndexPath? = nil, placeholder: UIImage? = nil, completion: ((CGFloat, IndexPath?) -> Void)? = nil) {
        
        let imagePlaceholder: UIImage?
        if let image = placeholder {
            imagePlaceholder = image
        } else {
            imagePlaceholder = getImageWithColor(color: UIColor.clear, size: self.frame.size)
        }
        
        
        
        sd_imageIndicator = SDWebImageActivityIndicator.gray
        sd_setImage(with: url, placeholderImage: imagePlaceholder, options: [.lowPriority]) { (image, error, cacheType, url) in
            if error == nil {
                let scale = self.frame.width / (image?.size.width)!
                let newHeight = (image?.size.height)! * scale
                if let comp = completion {
                    comp(newHeight, indexPath)
                }
            } else {
                self.image = imagePlaceholder
            }
        }
        
    }
    
    func getImageWithColor(color: UIColor, size: CGSize) -> UIImage? {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: size.width, height: size.height))
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return image
    }
    
}




extension UIImage {
    
    static func setImage(from url: URL?, completion: ((UIImage) -> Void)? = nil) {
        SDWebImageManager.shared.loadImage(with: url, options: [.lowPriority], progress: nil) { (image, data, error, cacheType, success, url) in
            
            if let image = image, error == nil {
                completion?(image)
            }
            
        }
    }

}

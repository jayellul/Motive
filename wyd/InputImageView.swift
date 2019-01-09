//
//  InputImageView.swift
//  wyd
//
//  Created by Jason Ellul on 2018-12-03.
//  Copyright © 2018 Jason Ellul. All rights reserved.
//

import UIKit

private let successImage = #imageLiteral(resourceName: "success.png")
private let errorImage = #imageLiteral(resourceName: "error.png")

// UIImageView class of a check and X for within a UITextView
class InputImageView: UIImageView {

    var success: Bool = false
    func setToError() {
        self.image = resizeImage(image: errorImage, targetSize: CGSize(width: 25, height: 25))
        success = false
    }
    
    func setToSuccess() {
        if success { return }
        success = true
        let expandTransform: CGAffineTransform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .transitionCrossDissolve, animations: {
            self.image = self.resizeImage(image: successImage, targetSize: CGSize(width: 25, height: 25))
        }) { (completion) in
            // add springy transform
            self.transform = expandTransform.inverted()

            UIView.animate(withDuration: 1.2, delay: 0.0, usingSpringWithDamping: 0.25, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                self.transform = CGAffineTransform.identity
            }) { (completion) in
            }
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    

}

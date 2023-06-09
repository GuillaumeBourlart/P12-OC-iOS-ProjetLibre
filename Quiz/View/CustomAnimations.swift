//
//  CustomAnimations.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 09/06/2023.
//

import Foundation
import UIKit

class CustomAnimations {
    static func buttonPressAnimation(for button: UIButton, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 6.0,
                       options: [.allowUserInteraction],
                       animations: {
            button.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: [.allowUserInteraction],
                           animations: {
                button.transform = CGAffineTransform.identity
            }) { _ in
                completion()
            }
        }
    }
    
    static func imagePressAnimation(for image: UIImageView, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 6.0,
                       options: [.allowUserInteraction],
                       animations: {
            image.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: [.allowUserInteraction],
                           animations: {
                image.transform = CGAffineTransform.identity
            }) { _ in
                completion()
            }
        }
    }
}

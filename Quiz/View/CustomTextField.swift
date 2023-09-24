//
//  CustomTextField.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 27/06/2023.
//

import Foundation
import UIKit

// Custom UITextField class with an image and styled placeholder
class CustomTextField: UITextField {
    
    // Private property for the image view
    private var imageView: UIImageView = UIImageView()
    
    // Initializer for creating the custom text field
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    // Required initializer for creating the custom text field from a storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    // Private function to set up the UI elements
    private func setupUI() {
        // Apply rounded corners to the text field
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
        
        // Customize the image view properties
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
        
        // Create a container view for the image view
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20)
        
        // Add the image view to the container view
        view.addSubview(imageView)
        
        // Set the left view mode to always display the container view
        self.leftViewMode = .always
        self.leftView = view
    }
    
    // Function to set up the image, placeholder text, and placeholder text color
    func setup(image: UIImage?, placeholder: String, placeholderColor: UIColor) {
        // Set the image for the image view
        imageView.image = image
        
        // Create an attributed placeholder with the specified color
        let attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
        self.attributedPlaceholder = attributedPlaceholder
    }
}


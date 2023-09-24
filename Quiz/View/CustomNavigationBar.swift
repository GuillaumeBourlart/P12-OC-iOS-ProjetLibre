//
//  CustomNavigationBar.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 27/06/2023.
//

import UIKit

// Custom UINavigationBar class with styling
class CustomNavigationBar: UINavigationBar {
    
    // Initializer for creating the custom navigation bar
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    // Required initializer for creating the custom navigation bar from a storyboard
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // Private function to set up the UI styling
    private func setupUI() {
        // Remove the background image to make the navigation bar transparent
        setBackgroundImage(UIImage(), for: .default)
        
        // Remove the shadow image to hide the navigation bar's shadow
        shadowImage = UIImage()
        
        // Make the navigation bar translucent
        isTranslucent = true
        
        // Set the tint color for navigation bar items
        tintColor = UIColor(named: "text")
        
        // Set the title text attributes (text color) for the navigation bar
        titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "text") ?? UIColor.magenta]
    }
}


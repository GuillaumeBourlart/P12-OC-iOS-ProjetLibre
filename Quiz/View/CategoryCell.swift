//
//  CategoryCell.swift
//  Quizz Culture générale
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import UIKit
// Custom category cell for CollectionView ( quiz categories )
class CategoryCell: UICollectionViewCell {
    // Outlets
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var image: UIImageView!
    
    // Function called when a cell is initialized from the Interface Builder
    override func awakeFromNib() {
        super.awakeFromNib()
        updateImageViewForCurrentTraitCollection() // Update when the cell is created
    }
    
    // Function called when there is a change in interface traits (such as dark or light mode)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Check if the current interface traits are different from the previous ones
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateImageViewForCurrentTraitCollection()
        }
    }
    
    // Function to update the view's image based on the current interface traits
    func updateImageViewForCurrentTraitCollection() {
        if traitCollection.userInterfaceStyle == .dark {
            // If dark mode is enabled
            self.image.image = UIImage(named: "darkCategoriesBackground")
        } else {
            // If dark mode is disabled (light mode)
            self.image.image = UIImage(named: "lightCategoriesBackground")
        }
    }
    
}

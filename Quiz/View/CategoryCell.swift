//
//  CategoryCell.swift
//  Quizz Culture générale
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import UIKit
// Custom category cell for CollectionView
class CategoryCell: UICollectionViewCell {
    @IBOutlet weak var categoryLabel: UILabel!
    
    @IBOutlet weak var image: UIImageView!
    
    override func awakeFromNib() {
            super.awakeFromNib()
            updateImageViewForCurrentTraitCollection() // Mettre à jour lorsque la cellule est créée
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateImageViewForCurrentTraitCollection()
            }
        }

        func updateImageViewForCurrentTraitCollection() {
            if traitCollection.userInterfaceStyle == .dark {
                // Mode sombre
                self.image.image = UIImage(named: "darkCategoriesBackground")
                self.categoryLabel.textColor = UIColor.white
            } else {
                // Mode clair
                self.image.image = UIImage(named: "lightCategoriesBackground")
                self.categoryLabel.textColor = UIColor.black
                
            }
        }
}

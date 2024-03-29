//
//  CustomButton.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 01/05/2023.
//

import UIKit
// Custom button
class CustomButton: UIButton {

    override init(frame: CGRect) {
            super.init(frame: frame)
            setupButton()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupButton()
        }
        
        private func setupButton() {
            // Définissez la couleur du texte du bouton
            setTitleColor(.white, for: .normal)
            
            
            // Définissez le border radius (arrondissement des coins) du bouton
            
            layer.cornerRadius = frame.height / 2
        }

}

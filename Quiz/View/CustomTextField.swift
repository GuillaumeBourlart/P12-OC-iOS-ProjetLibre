//
//  CustomTextField.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 27/06/2023.
//

import Foundation
import UIKit

class CustomTextField: UITextField {

    private var imageView: UIImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit

        let view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20)

        view.addSubview(imageView)

        self.leftViewMode = .always
        self.leftView = view
    }

    func setup(image: UIImage?, placeholder: String, placeholderColor: UIColor) {
        imageView.image = image
        let attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
        self.attributedPlaceholder = attributedPlaceholder
    }
}

//
//  CustomNavigationBar.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 27/06/2023.
//

import UIKit

class CustomNavigationBar: UINavigationBar {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
        isTranslucent = true
        tintColor = UIColor(named: "text")
        titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "text") ?? UIColor.magenta]
    }
}

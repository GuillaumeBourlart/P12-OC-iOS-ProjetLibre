//
//  TableViewCell.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 06/07/2023.
//

import UIKit

class EmptyCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Customisation du label
        label.text = "Pull to refresh"
        label.font = UIFont.boldSystemFont(ofSize: 18)
    }
}
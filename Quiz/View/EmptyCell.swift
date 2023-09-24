//
//  TableViewCell.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 06/07/2023.
//

import UIKit
import SDWebImage

// Custom UITableViewCell class for an empty cell
class EmptyCell: UITableViewCell {
    // Outlets
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Customize the label within the cell
        label.text = "Pull to refresh" // Set the label text
        label.font = UIFont.boldSystemFont(ofSize: 18) // Apply a bold font to the label
    }
}

//
//  CustomTableViewCell.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 23/04/2023.
//

import UIKit

// Protocol to define custom cell delegate methods
protocol CustomCellDelegate: AnyObject {
    // Method to handle the tap event on the "Add" button within the cell
    func didTapAddButton(in cell: CustomCell)
    
    // Method to handle the tap event on the "Remove" button within the cell
    func didTapRemoveButton(in cell: CustomCell)
}


// Custom cell for TableView
class CustomCell: UITableViewCell {
    // Outlets
    @IBOutlet weak var addButton: UIButton?
    @IBOutlet weak var removeButton: UIButton?
    @IBOutlet var label: UILabel!
    // Properties
    weak var delegate: CustomCellDelegate? // delegate
    
    // Action method called when the "Add" button is tapped
    @IBAction func addButtonTapped(_ sender: UIButton) {
        delegate?.didTapAddButton(in: self)
    }
    
    // Action method called when the "Remove" button is tapped
    @IBAction func removeButtonTapped(_ sender: UIButton) {
        delegate?.didTapRemoveButton(in: self)
    }
    
}

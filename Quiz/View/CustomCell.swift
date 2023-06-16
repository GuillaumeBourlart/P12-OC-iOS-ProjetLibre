//
//  CustomTableViewCell.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 23/04/2023.
//

import UIKit

protocol CustomCellDelegate: AnyObject {
    func didTapAddButton(in cell: CustomCell)
    func didTapRemoveButton(in cell: CustomCell)}
// Custom cell for TableView
class CustomCell: UITableViewCell {
    
    @IBOutlet weak var addButton: UIButton?
    @IBOutlet weak var removeButton: UIButton?
    @IBOutlet var label: UILabel!
    
    
    weak var delegate: CustomCellDelegate?
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        delegate?.didTapAddButton(in: self)
    }
    
    
    
    @IBAction func removeButtonTapped(_ sender: UIButton) {
        delegate?.didTapRemoveButton(in: self)
    }
    
    
    
    
}

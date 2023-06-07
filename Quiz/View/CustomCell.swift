//
//  CustomTableViewCell.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 23/04/2023.
//

import UIKit

protocol CustomCellDelegate: AnyObject {
    func didTapAddButton(in cell: CustomCell)
    func didTapRemoveButton(in cell: CustomCell)
}
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
    
    func configure(isFriendCell: Bool) {
        // Si c'est une cellule d'ami, on montre les boutons
        addButton?.isHidden = !isFriendCell
        removeButton?.isHidden = !isFriendCell
    }
    
    func roundTopCorners() {
           let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10))
           let shape = CAShapeLayer()
           shape.path = maskPath.cgPath
           layer.mask = shape
       }

       func roundBottomCorners() {
           let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 10, height: 10))
           let shape = CAShapeLayer()
           shape.path = maskPath.cgPath
           layer.mask = shape
       }
    
    func resetCorners() {
        layer.mask = nil
    }
}

//
//  CustomTableViewCell.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 23/04/2023.
//

import UIKit


protocol FriendTableViewCellDelegate: AnyObject {
    func didTapAddButton(in cell: CustomFriendCell)
    func didTapRemoveButton(in cell: CustomFriendCell)
}

class CustomFriendCell: UITableViewCell {
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    
    @IBOutlet var username: UILabel?

    weak var delegate: FriendTableViewCellDelegate?

       @IBAction func addButtonTapped(_ sender: UIButton) {
           delegate?.didTapAddButton(in: self)
       }

       @IBAction func removeButtonTapped(_ sender: UIButton) {
           delegate?.didTapRemoveButton(in: self)
       }

}

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
    
    func didChangeSwitchValue(in cell: CustomCell, isOn: Bool)
}
// Custom cell for TableView
class CustomCell: UITableViewCell {
    
    @IBOutlet weak var addButton: UIButton?
    @IBOutlet weak var removeButton: UIButton?
    @IBOutlet var label: UILabel!
    
    var customImage: UIImageView?
    var customSwitch: UISwitch?
    var cellType: CellControlType? {
        didSet {
            setNeedsLayout() // cela déclenchera un appel à `layoutSubviews()`
        }
    }
    
    weak var delegate: CustomCellDelegate?
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        delegate?.didTapAddButton(in: self)
    }
    
    
    
    @IBAction func removeButtonTapped(_ sender: UIButton) {
        delegate?.didTapRemoveButton(in: self)
    }
    
    @objc func switchValueChanged(_ sender: UISwitch) {
        delegate?.didChangeSwitchValue(in: self, isOn: sender.isOn)
        
    }
    
    
    func configure(isFriendCell: Bool, cellType: CellControlType) {
        // Si c'est une cellule d'ami, on montre les boutons
        // Si c'est une cellule d'ami, on montre les boutons
        addButton?.isHidden = !isFriendCell
        removeButton?.isHidden = !isFriendCell
        if isFriendCell == false {
            self.cellType = cellType
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let cellType = cellType {
            switch cellType {
            case .switch:
                if customSwitch == nil {
                    let switchWidth: CGFloat = 51.0
                    let switchHeight: CGFloat = 31.0
                    let xPosition = self.contentView.frame.width - switchWidth - 15.0
                    let yPosition = (self.contentView.frame.height - switchHeight) / 2.0
                    customSwitch = UISwitch(frame: CGRect(x: xPosition, y: yPosition, width: switchWidth, height: switchHeight))
                    customSwitch?.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
                    if let switchElement = customSwitch {
                        self.contentView.addSubview(switchElement)
                    }
                }
                customSwitch?.onTintColor = UIColor(named: "button2")
                customSwitch?.isHidden = false
                if let sound = UserDefaults.standard.object(forKey: "sound") {
                    let isOn = UserDefaults.standard.bool(forKey: "sound")
                    customSwitch?.isOn = isOn
                }
            case .none:
                if customImage == nil {
                    let imageWidth: CGFloat = 30.0
                    let imageHeight: CGFloat = 30.0
                    let xPosition = self.contentView.frame.width - imageWidth - 15.0
                    let yPosition = (self.contentView.frame.height - imageHeight) / 2.0
                    customImage = UIImageView(frame: CGRect(x: xPosition, y: yPosition, width: imageWidth, height: imageHeight))
                    if let imageElement = customImage {
                        imageElement.image = UIImage(systemName: "arrow.right") // Remplacez "myImageName" par le nom de votre image
                        imageElement.contentMode = .scaleAspectFit // ou tout autre mode que vous préférez
                        self.contentView.addSubview(imageElement)
                        imageElement.tintColor = UIColor.white
                    }
                }
                customImage?.isHidden = false
                customSwitch?.isHidden = true
            }
        }
    }
}

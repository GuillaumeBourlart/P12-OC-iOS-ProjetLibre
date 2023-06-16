//
//  SettingsCell.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 14/06/2023.
//

import Foundation
import UIKit

protocol SettingsCellDelegate: AnyObject {
    func didChangeSwitchValue(in cell: SettingsCell, isOn: Bool)
}

class SettingsCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    weak var delegate: SettingsCellDelegate?
    
    var sectionType: SectionType? {
        didSet {
            guard let sectionType = sectionType else { return }
            self.label.text = sectionType.description
            switchControl.isHidden = !sectionType.containsSwitch
        }
    }

    lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isOn = true
        switchControl.onTintColor = UIColor(named: "button2")
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.addTarget(self, action: #selector(handleSwitchAction), for: .valueChanged)
        return switchControl
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSwitchControl()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSwitchControl()
    }
    
    private func setupSwitchControl() {
        // Ajout du switchControl comme sous-vue
        self.contentView.addSubview(switchControl)
        
        // Configuration des contraintes pour le positionnement du switchControl
        NSLayoutConstraint.activate([
            switchControl.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -10),
            switchControl.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor)
        ])
        
        
        let defaults = UserDefaults.standard
        if let _ = defaults.object(forKey: "sound") {
            // L'utilisateur a déjà défini une valeur pour "sound", utilisez cette valeur.
            let sound = defaults.bool(forKey: "sound")
            self.switchControl.isOn = sound
        } else {
            self.switchControl.isOn = true
        }
    }
    
    @objc func handleSwitchAction(sender: UISwitch) {
            delegate?.didChangeSwitchValue(in: self, isOn: sender.isOn)
    }
}

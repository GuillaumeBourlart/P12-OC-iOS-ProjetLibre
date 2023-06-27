//
//  SettingsCell.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 14/06/2023.
//

import Foundation
import UIKit

protocol SettingsCellDelegate: AnyObject {
    func SoundSwitchChanged(in cell: SettingsCell, isOn: Bool)
    func DarkmodeSwitchChanged(in cell: SettingsCell, isOn: Bool)
}

class SettingsCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    weak var delegate: SettingsCellDelegate?
    var currentOption: SectionType?
    
    var sectionType: SectionType? {
        didSet {
            guard let sectionType = sectionType else { return }
            self.label.text = sectionType.description
            switchControl.isHidden = !sectionType.containsSwitch
            self.currentOption = sectionType
        
            if let accountOption = sectionType as? SettingsSections.AccountOptions, accountOption == .disconnect {
                backgroundColor = UIColor.red
                    } 
            
            setupSwitchControl()
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
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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
           guard let option = currentOption as? SettingsSections.SecurityOptions else {
               return
           }

           switch option {
           case .sounds:
               // L'utilisateur a déjà défini une valeur pour "sound", utilisez cette valeur.
               if let _ = defaults.object(forKey: "sound") {
                   let sound = defaults.bool(forKey: "sound")
                   self.switchControl.isOn = sound
               } else {
                   self.switchControl.isOn = true
               }
           case .darkmode:
               // L'utilisateur a déjà défini une valeur pour "darkmode", utilisez cette valeur.
               if let _ = defaults.object(forKey: "darkmode") {
                   let darkmode = defaults.bool(forKey: "darkmode")
                   self.switchControl.isOn = darkmode
               } else {
                   self.switchControl.isOn = false // supposons que le mode par défaut est light mode
               }
           }
    }
    
    
    @objc func handleSwitchAction(sender: UISwitch) {
        

        guard let option = currentOption as? SettingsSections.SecurityOptions else {
            return
        }

        switch option {
        case .sounds:
            // Code pour gérer le son
            delegate?.SoundSwitchChanged(in: self, isOn: sender.isOn)
        case .darkmode:
            // Code pour gérer le mode sombre
            delegate?.DarkmodeSwitchChanged(in: self, isOn: sender.isOn)
        }
    }
}

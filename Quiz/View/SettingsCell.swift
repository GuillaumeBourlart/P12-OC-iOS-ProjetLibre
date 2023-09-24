//
//  SettingsCell.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 14/06/2023.
//

import Foundation
import UIKit

// Protocol to define delegate methods for settings cell
protocol SettingsCellDelegate: AnyObject {
    func SoundSwitchChanged(in cell: SettingsCell, isOn: Bool)
}

// Class for custom settings cells
class SettingsCell: UITableViewCell {
    // Outlets
    @IBOutlet weak var label: UILabel!
    // Properties
    // Weak reference to the delegate
    weak var delegate: SettingsCellDelegate?
    
    // The current setting option
    var currentOption: SectionType?
    
    // Property to store the section type and update the cell
    var sectionType: SectionType? {
        didSet {
            guard let sectionType = sectionType else { return }
            
            // Set the label text based on the section type description
            self.label.text = sectionType.description
            
            // Show or hide the switch control based on the section type
            switchControl.isHidden = !sectionType.containsSwitch
            
            // Store the current option
            self.currentOption = sectionType
            
            // Customize cell background color for specific options
            if let accountOption = sectionType as? SettingsSections.AccountOptions, accountOption == .disconnect {
                self.backgroundColor = self.backgroundColor?.withAlphaComponent(0.5)
            }
            
            // Set up the switch control
            setupSwitchControl()
        }
    }
    
    // Lazy initialization of the switch control
    lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.isOn = true
        switchControl.onTintColor = UIColor(named: "button2")
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.addTarget(self, action: #selector(handleSwitchAction), for: .valueChanged)
        return switchControl
    }()
    
    // Initializer for the custom cell
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // Function to set up the switch control
    private func setupSwitchControl() {
        // Add the switchControl as a subview
        self.contentView.addSubview(switchControl)
        
        // Set up constraints for the switchControl's position
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
            // Check if the user has previously set a value for "sound" and update the switch
            if let _ = defaults.object(forKey: "sound") {
                let sound = defaults.bool(forKey: "sound")
                self.switchControl.isOn = sound
            } else {
                self.switchControl.isOn = true
            }
        }
    }
    
    // Function to handle switch action
    @objc func handleSwitchAction(sender: UISwitch) {
        guard let option = currentOption as? SettingsSections.SecurityOptions else {
            return
        }
        switch option {
        case .sounds:
            // Handle sound switch action and notify the delegate
            delegate?.SoundSwitchChanged(in: self, isOn: sender.isOn)
        }
    }
}

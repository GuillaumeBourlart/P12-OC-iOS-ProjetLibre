//
//  ProfileVC.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 24/04/2023.
//

import Foundation
import UIKit

class ProfilVC: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    override func viewDidLoad() {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QuizzGroupsVC {
            print("1")
            guard let text = sender as? String else { return }
            if text == "Groupe" {
                destination.isQuizList = false
                print("2")
            }else{
                destination.isQuizList = true
                print("3")
            }
            
        }
    }
    
    
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let settingsSection = SettingsSection(rawValue: section) else { return 0 }
        
        switch settingsSection {
        case .account:
            return SettingsSection.Account.allCases.count
        case .security:
            return SettingsSection.Security.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        guard let settingsSection = SettingsSection(rawValue: indexPath.section) else { return cell }
        
        switch settingsSection {
        case .account:
            if let accountOption = SettingsSection.Account(rawValue: indexPath.row) {
                cell.textLabel?.text = accountOption.title
            }
        case .security:
            if let securityOption = SettingsSection.Security(rawValue: indexPath.row) {
                cell.textLabel?.text = securityOption.title
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SettingsSection(rawValue: section)?.title
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let settingsSection = SettingsSection(rawValue: indexPath.section) else { return }
        
        
        
        switch settingsSection {
        case .account:
            if let accountOption = SettingsSection.Account(rawValue: indexPath.row) {
                print("L'utilisateur a sélectionné l'option \(accountOption.title) dans la section Compte")
                performSegue(withIdentifier: accountOption.segueIdentifier, sender: accountOption.title)
            }
        case .security:
            if let securityOption = SettingsSection.Security(rawValue: indexPath.row) {
                print("L'utilisateur a sélectionné l'option \(securityOption.title) dans la section Sécurité")
                performSegue(withIdentifier: securityOption.segueIdentifier, sender: securityOption.title)
            }
        }
    }
}


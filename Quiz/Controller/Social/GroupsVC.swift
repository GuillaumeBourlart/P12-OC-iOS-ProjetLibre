//
//  groupVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 22/06/2023.
//

import Foundation
import UIKit

class GroupsVC: UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    
    var groups: [FriendGroup] { return FirebaseUser.shared.friendGroups ?? [] }
    var activeAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.3)
    }
    
    override func viewWillAppear(_ animated: Bool) {
            FirebaseUser.shared.getUserGroups { result in
                switch result {
                case .success():
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error getting groups: \(error.localizedDescription)")
                    // Afficher une alerte à l'utilisateur ou gérer l'erreur de manière appropriée
                }
            }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // If an alert is being displayed, dismiss it
               if let activeAlert = activeAlert {
                   activeAlert.dismiss(animated: false)
                   self.activeAlert = nil
               }
    }
    
    
    @IBAction func plusButtonTapped(_ sender: Any) {
            displayAddGroupAlert()
    }
    
    
    func displayAddGroupAlert() {
        let alert = UIAlertController(title: "Add a group", message: "Enter group name", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Name"
            textField.autocorrectionType = .no
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { (_) in
            guard let name = alert.textFields?[0].text, !name.isEmpty else { return }
            
            FirebaseUser.shared.addGroup(name: name) { result in
                switch result {
                case .success():
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error adding group : \(error.localizedDescription)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        self.activeAlert = alert
        
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ModifyGroupVC {
            if let group = sender as? FriendGroup {
                destination.groupID = group.id
            }
        }
    }
    
}

extension GroupsVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
                let groupToDelete = groups[indexPath.row]
                FirebaseUser.shared.deleteGroup(group: groupToDelete) { result in
                    switch result {
                    case .success:
                        tableView.reloadData()
                    case .failure(let error):
                        print("Error removing group : \(error.localizedDescription)")
                    }
                }
            
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 70.0 // Remplacer par la hauteur désirée
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Désélectionnez la cellule pour une meilleure expérience utilisateur
        
            let selectedGroup = groups[indexPath.row]
            print("Selected group : \(selectedGroup)")
            performSegue(withIdentifier: "goToModifyGroups", sender: selectedGroup)
        }
    
}


extension GroupsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomCell
        
            cell.label.text = groups[indexPath.row].name
        
        
        let whiteDisclosureIndicator = UIImageView(image: UIImage(systemName: "chevron.right"))
        whiteDisclosureIndicator.tintColor = .white // Remplacez "customDisclosureIndicator" par le nom de votre image.
        whiteDisclosureIndicator.backgroundColor = UIColor.clear
        whiteDisclosureIndicator.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
        cell.accessoryView = whiteDisclosureIndicator
        
        return cell
    }
}


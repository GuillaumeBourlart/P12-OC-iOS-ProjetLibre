//
//  groupVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 22/06/2023.
//

import Foundation
import UIKit

class GroupsVC: UIViewController{
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    // Properties
    var groups: [FriendGroup] { return FirebaseUser.shared.friendGroups ?? [] } // Calculated propertie to get all groups of user
    var activeAlert: UIAlertController? // For alert displaying
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // Method called when view will appear
    override func viewWillAppear(_ animated: Bool) {
        // try to get user groups
        FirebaseUser.shared.getUserGroups { result in
            switch result {
            case .success():
                self.tableView.reloadData()
            case .failure(let error):
                print("Error getting groups: \(error.localizedDescription)")
            }
        }
    }
    
    // Method called when view will disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // If an alert is being displayed, dismiss it
        if let activeAlert = activeAlert {
            activeAlert.dismiss(animated: false)
            self.activeAlert = nil
        }
    }
    
    // display an alert when user push the button
    @IBAction func plusButtonTapped(_ sender: Any) {
        displayAddGroupAlert()
    }
    
    // function that display an alert so the user can create a group and choose a name
    func displayAddGroupAlert() {
        var alertTitle = NSLocalizedString("Add a group", comment: "")
        let alertMessage = NSLocalizedString("Enter group name", comment: "")
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Name"
            textField.autocorrectionType = .no
        }
        alertTitle = NSLocalizedString("Add", comment: "")
        let addAction = UIAlertAction(title: alertTitle, style: .default) { (_) in
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
        let cancel = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancel, style: .cancel)
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        self.activeAlert = alert
        present(alert, animated: true)
    }
    
    // called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ModifyGroupVC {
            if let group = sender as? FriendGroup {
                destination.groupID = group.id
            }
        }
    }
}

// UITableViewDelegate methods for handling table view actions
extension GroupsVC: UITableViewDelegate {
    
    // Handle deletion of a group when swiping left on a cell
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let groupToDelete = groups[indexPath.row]
        FirebaseUser.shared.deleteGroup(group: groupToDelete) { result in
            switch result {
            case .success:
                tableView.reloadData() // Reload the table view to reflect the changes
            case .failure(let error):
                print("Error removing group : \(error.localizedDescription)")
            }
        }
    }
    
    // Set the height for table view cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0 // Replace with the desired cell height
    }
    
    // Handle selection of a table view cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Deselect the cell for a better user experience
        
        let selectedGroup = groups[indexPath.row]
        print("Selected group : \(selectedGroup)")
        performSegue(withIdentifier: "goToModifyGroups", sender: selectedGroup)
    }
}

// UITableViewDataSource methods for providing data to the table view
extension GroupsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomCell
        // Set the cell label to display the group name
        cell.label.text = groups[indexPath.row].name
        // Create the disclosure indicator for the cell
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}



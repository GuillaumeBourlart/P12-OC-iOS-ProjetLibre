//
//  AddMemberVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 03/06/2023.
//

import Foundation
import UIKit

class AddMemberVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var validateButton: CustomButton!
    
    var group: FriendGroup?
    var friends: [String: String] = [:]
    var selectedFriends: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFriends()
    }
    
    func loadFriends(){
        let friends = FirebaseUser.shared.fetchFriends(){data, error in
            if let error = error {
                print(error)
            }
            if let data = data {
                self.friends = data
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func validateButtonPressed(_ sender: Any) {
        CustomAnimations.buttonPressAnimation(for: self.validateButton) {
            self.validateButton.isEnabled = false
            if let group = self.group {
                FirebaseUser.shared.addNewMembersToGroup(group: group, newMembers: self.selectedFriends) { result in
                    switch result {
                    case .failure(let error): print(error)
                        self.validateButton.isEnabled = true
                    case .success: self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
        
    
    }
    
}


extension AddMemberVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell

        // Get memberId from friends keys
        let memberId = Array(self.friends.keys)[indexPath.row]
        let memberUsername = self.friends[memberId] // Get username from friends values

        cell.label.text = memberUsername

        // Update the cell's accessoryType to indicate selection
        if selectedFriends.contains(memberId) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0 // Remplacer par la hauteur désirée
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get memberId from friends keys
        let memberId = Array(self.friends.keys)[indexPath.row]
        
        // Check if member is already selected
        if let index = selectedFriends.firstIndex(of: memberId) {
            // Member is already selected, so remove them from selectedFriends
            selectedFriends.remove(at: index)
        } else {
            // Member is not selected, so add them to selectedFriends
            selectedFriends.append(memberId)
        }
        
        // Update the selection state of the cell
        tableView.reloadRows(at: [indexPath], with: .none)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}


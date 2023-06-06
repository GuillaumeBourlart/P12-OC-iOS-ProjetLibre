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
        if let group = group {
            FirebaseUser.shared.addNewMembersToGroup(group: group, newMembers: selectedFriends) { result in
                switch result {
                case .failure(let error): print(error)
                case .success: self.navigationController?.popViewController(animated: true)
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

        // Update the cell's background color to indicate selection
        if selectedFriends.contains(memberId) {
            cell.backgroundColor = .lightGray // Replace this with the desired color for selected cells
        } else {
            cell.backgroundColor = .white // Replace this with the desired color for non-selected cells
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
        if selectedFriends.contains(memberId) {
            // Member is already selected, so remove them from selectedFriends
            selectedFriends = selectedFriends.filter { $0 != memberId }
        } else {
            // Member is not selected, so add them to selectedFriends
            selectedFriends.append(memberId)
        }
        
        // Update the selection state of the cell
        tableView.reloadData()
    }
    
}


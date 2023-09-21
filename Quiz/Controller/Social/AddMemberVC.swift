//
//  AddMemberVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 03/06/2023.
//

import Foundation
import UIKit

class AddMemberVC: UIViewController {
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var validateButton: CustomButton!
    // Properties
    var group: FriendGroup?
    var friends: [String: String] = [:]
    var selectedFriends: [String] = []
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFriends()
    }
    
    // display friends
    func loadFriends(){
        FirebaseUser.shared.fetchFriends(){data, error in
            if let error = error {
                print(error)
            }
            if let data = data {
                self.friends = data
                self.tableView.reloadData()
            }
        }
    }
    
    // add selected members to the group when button is pressed
    @IBAction func validateButtonPressed(_ sender: Any) {
        CustomAnimations.buttonPressAnimation(for: self.validateButton) {
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
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
// UITableViewDelegate and UITableViewDataSource methods for handling table view actions
extension AddMemberVC: UITableViewDelegate, UITableViewDataSource {
    
    // Configure and provide cells for the table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell

        let memberId = Array(self.friends.keys)[indexPath.row] // Get memberId from friends keys
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
    
    // Define the number of rows in the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    // Define the height for table view rows
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
   
    // Handle row selection and updating the selection state
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



//
//  InvitePlayers.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 24/05/2023.
//

import Foundation
import UIKit

// Class to invite players
class InvitePlayersVC: UIViewController{
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    // Properties
    var lobbyID: String? // ID of the lobby
        var isShowingFriends = true // Indicates if friends are currently displayed
        var friends: [String: String] = [:] // Dictionary to store friends (UID and username)
        var groups: [FriendGroup] { return FirebaseUser.shared.friendGroups ?? [] } // Array of friend groups
        var selectedFriends: [String] = [] // Array to store selected friends
        var selectedGroups: [FriendGroup] = [] // Array to store selected friend groups
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: true)
        tabBarController?.tabBar.isHidden = true
        
        loadFriends()
    }
    
    // Method called when view will disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    // Method to validate chosen friends and groups  and invite them
    @IBAction func validateButton(_ sender: Any) {
        guard let lobbyID = lobbyID else { return}
        Game.shared.invitePlayerInRoom(lobbyId: lobbyID, invited_players: selectedFriends, invited_groups: selectedGroups.map { $0.id }) { result in
            switch result {
            case .failure(let error): print(error)
            case .success():self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // Function to fetch the list of friends
    func loadFriends(){
        FirebaseUser.shared.fetchFriends { data, error in
            if let error = error {
                print(error)
            }
            if let data = data{
                self.friends = data
                self.tableView.reloadData()
            }
        }
    }
    
    // Action method when the segmented control is switched
    @IBAction func onSwitch(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        switch index {
        case 0:
            isShowingFriends = true
            tableView.reloadData()
            
        case 1:
            isShowingFriends = false
            tableView.reloadData()
            
            
        default:
            break
        }
    }
    
}

extension InvitePlayersVC: UITableViewDelegate, UITableViewDataSource {
    
    // Function to specify the height for each row in the table view
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0 // Replace with the desired height for table view rows
    }
    
    // Function to specify the number of rows in the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isShowingFriends {
            return friends.count // Number of friends to display
        } else {
            return groups.count // Number of friend groups to display
        }
    }
    
    // Function to configure and return a cell for a given row and section
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
        
        if isShowingFriends {
            // Configure friend cell
            let friendKey = Array(friends.keys)[indexPath.row]
            cell.label.text = friends[friendKey] // Display friend's username
            cell.accessoryType = selectedFriends.contains(friendKey) ? .checkmark : .none // Show checkmark if friend is selected
        } else {
            // Configure group cell
            let group = groups[indexPath.row]
            cell.label.text = group.name // Display group name
            cell.accessoryType = selectedGroups.contains(where: { $0.id == group.id }) ? .checkmark : .none // Show checkmark if group is selected
        }
        
        return cell
    }
    
    // Function called when a row is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isShowingFriends {
            // Handle friend selection/deselection
            let friendKey = Array(friends.keys)[indexPath.row]
            if let index = selectedFriends.firstIndex(of: friendKey) {
                selectedFriends.remove(at: index) // Deselect friend
            } else {
                selectedFriends.append(friendKey) // Select friend
            }
        } else {
            // Handle group selection/deselection
            let group = groups[indexPath.row]
            if let index = selectedGroups.firstIndex(where: { $0.id == group.id }) {
                selectedGroups.remove(at: index) // Deselect group
            } else {
                selectedGroups.append(group) // Select group
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
        
        tableView.reloadData() // Refresh the table view to update selections
    }
}

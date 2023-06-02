//
//  CustomTableView.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 03/05/2023.
//

import Foundation
import UIKit

class SelectFriendsTableViewController: UITableViewController {
    var friends: [String: String] = [:]
    var selectedFriends: [String: String] = [:]

    override func viewDidLoad() {
            super.viewDidLoad()
            tableView.allowsMultipleSelection = true
            tableView.register(FriendCell.self, forCellReuseIdentifier: "Cell")
        }
        
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return friends.count
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let friendUid = Array(friends.keys)[indexPath.row]
            let friendName = friends[friendUid] ?? ""
            cell.textLabel?.text = friendName
            return cell
        }

        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let selectedFriendUID = Array(friends.keys)[indexPath.row]
            let selectedFriendName = friends[selectedFriendUID] ?? ""
            selectedFriends[selectedFriendUID] = selectedFriendName
        }

        override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
            let deselectedFriendUID = Array(friends.keys)[indexPath.row]
            selectedFriends.removeValue(forKey: deselectedFriendUID)
        }
}


class FriendCell: UITableViewCell {
    // Ajoutez vos outlets et autres propriétés ici
}

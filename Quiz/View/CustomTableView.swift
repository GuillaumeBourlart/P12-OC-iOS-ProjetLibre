//
//  CustomTableView.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 03/05/2023.
//

import Foundation
import UIKit

class SelectFriendsTableViewController: UITableViewController {
    var friends: [String] = []
    var selectedFriends: [String] = []

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
        let friendName = friends[indexPath.row]
        cell.textLabel?.text = friendName
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFriendUID = friends[indexPath.row]
        if !selectedFriends.contains(selectedFriendUID) {
            selectedFriends.append(selectedFriendUID) // Ajoutez l'UID de l'ami sélectionné à selectedFriends
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let deselectedFriendUID = friends[indexPath.row]
        if let index = selectedFriends.firstIndex(of: deselectedFriendUID) {
            selectedFriends.remove(at: index) // Supprimez l'UID de l'ami désélectionné de selectedFriends
        }
    }
}


class FriendCell: UITableViewCell {
    // Ajoutez vos outlets et autres propriétés ici
}

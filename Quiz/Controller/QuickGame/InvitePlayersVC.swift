//
//  InvitePlayers.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 24/05/2023.
//

import Foundation
import UIKit


class InvitePlayersVC: UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    
    var lobbyID: String?
    var isShowingFriends = true
    var friends : [String: String] = [:]
    var groups : [FriendGroup] { return FirebaseUser.shared.friendGroups ?? [] }
    var selectedFriends: [String] = []
    var selectedGroups: [FriendGroup] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: true)
        tabBarController?.tabBar.isHidden = true
        
        loadFriends()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func validateButton(_ sender: Any) {
        guard let lobbyID = lobbyID else { return}
        Game.shared.invitePlayerInRoom(lobbyId: lobbyID, invited_players: selectedFriends, invited_groups: selectedGroups.map { $0.id }) { result in
            switch result {
            case .failure(let error): print(error)
            case .success():self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
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

extension InvitePlayersVC: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0 // Remplacer par la hauteur désirée
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isShowingFriends {
            return friends.count
        }else {
            return groups.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
        
        if isShowingFriends {
            // Configure friend cell
            let friendKey = Array(friends.keys)[indexPath.row]
            cell.label.text = friends[friendKey]
            cell.accessoryType = selectedFriends.contains(friendKey) ? .checkmark : .none
        } else {
            // Configure group cell
            let group = groups[indexPath.row]
            cell.label.text = group.name
            cell.accessoryType = selectedGroups.contains(where: { $0.id == group.id }) ? .checkmark : .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isShowingFriends {
            // Handle friend selection/deselection
            let friendKey = Array(friends.keys)[indexPath.row]
            if let index = selectedFriends.firstIndex(of: friendKey) {
                selectedFriends.remove(at: index)
            } else {
                selectedFriends.append(friendKey)
            }
        } else {
            // Handle group selection/deselection
            let group = groups[indexPath.row]
            if let index = selectedGroups.firstIndex(where: { $0.id == group.id }) {
                selectedGroups.remove(at: index)
            } else {
                selectedGroups.append(group)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
        
        tableView.reloadData()
    }
}

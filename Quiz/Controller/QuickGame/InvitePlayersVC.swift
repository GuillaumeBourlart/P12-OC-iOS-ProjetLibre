//
//  InvitePlayers.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 24/05/2023.
//

import Foundation
import UIKit


class InvitePlayersVC: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: true)
            tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = false
    }

    
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBAction func validateButton(_ sender: Any) {
        Game.shared.invitePlayerInRoom(lobbyId: lobbyID!, invited_players: selectedFriends, invited_groups: selectedGroups.map { $0.id }) { result in
            switch result {
            case .failure(let error): print(error)
            case .success():self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    var lobbyID: String?
    var isShowingFriends = true
    var friends : [String] { return FirebaseUser.shared.userInfo?.friends ?? [] }
    var groups : [FriendGroup] { return FirebaseUser.shared.friendGroups ?? [] }
    
    var selectedFriends: [String] = []
    var selectedGroups: [FriendGroup] = []
    
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
            let friend = friends[indexPath.row]
            cell.label.text = friend

            // Vérifiez si l'ami est dans la liste des amis sélectionnés et mettez en évidence la cellule en conséquence
            cell.accessoryType = selectedFriends.contains(friend) ? .checkmark : .none
        } else {
            let group = groups[indexPath.row]
            cell.label!.text = group.name

            // Vérifiez si le groupe est dans la liste des groupes sélectionnés et mettez en évidence la cellule en conséquence
            cell.accessoryType = selectedGroups.contains(where: { $0.name == group.name }) ? .checkmark : .none
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isShowingFriends {
            // On récupère l'ami correspondant à l'index
            let friend = friends[indexPath.row]
            
            // On vérifie si l'ami est déjà dans la liste des amis sélectionnés
            if let index = selectedFriends.firstIndex(of: friend) {
                // Si oui, on le supprime de la liste
                selectedFriends.remove(at: index)
            } else {
                // Sinon, on l'ajoute à la liste
                selectedFriends.append(friend)
            }
        } else {
            let group = groups[indexPath.row]
            
            if let index = selectedGroups.firstIndex(where: { $0.name == group.name }) {
                // Si le groupe est déjà dans la liste des groupes sélectionnés, on le supprime
                selectedGroups.remove(at: index)
                
                // Supprimer les membres du groupe de la liste des joueurs sélectionnés
                let groupMembers = group.members.map { $0 }
                selectedFriends.removeAll { groupMembers.contains($0) }
            } else {
                // Si le groupe n'est pas dans la liste des groupes sélectionnés, on l'ajoute
                selectedGroups.append(group)
                
                // Ajouter les membres du groupe à la liste des joueurs sélectionnés
                let groupMembers = group.members.map { $0 }
                selectedFriends.append(contentsOf: groupMembers)
            }
            
            tableView.reloadData()
        }
    }
    
}

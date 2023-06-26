//
//  FriendsListVC.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 23/04/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import UIKit

class FriendsVC: UIViewController{
    
    @IBOutlet weak var switchControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    // variables
    var userListener: ListenerRegistration?
    var friends: [String: String] = [:]
    var friendRequests: [String: String] = [:]
    var isShowingFriendRequests = true
    var activeAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshTable), name: NSNotification.Name("DataUpdated"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadArrays()
        onSwitch(switchControl)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // If an alert is being displayed, dismiss it
               if let activeAlert = activeAlert {
                   activeAlert.dismiss(animated: false)
                   self.activeAlert = nil
               }
    }
    
    @objc func refreshTable() {
            self.loadArrays()
        
    }
    
    
    // Load friends array and friend requests array for displaying
    func loadArrays(){
        FirebaseUser.shared.fetchFriends { data, error in
            if let error = error {
                print(error)
            }
            if let data = data {
                DispatchQueue.main.async {
                    self.friends = data
                    self.tableView.reloadData()
                }
                
            }
        }
        FirebaseUser.shared.fetchFriendRequests() { data, error in
            if let error = error {
                print(error)
            }
            if let data = data {
                DispatchQueue.main.async {
                    self.friendRequests = data
                    self.tableView.reloadData()
                }
                
            }
        }
    }
    
    // Function called when switching UIsegmentedCotroll index
    @IBAction func onSwitch(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: isShowingFriendRequests = false
            self.tableView.reloadData()
            
        case 1: isShowingFriendRequests = true
            self.tableView.reloadData()
            
        default:
            print("error")
        }
    }
    
    // Function called when player wants to add a friend
    @IBAction func addFriend(sender: UIButton){
        let alertController = UIAlertController(title: "Ajouter un ami", message: "Entrez le nom d'utilisateur de votre ami", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Nom d'utilisateur"
        }
        
        let addAction = UIAlertAction(title: "Ajouter", style: .default) { (_) in
            guard let username = alertController.textFields?.first?.text, !username.isEmpty else {
                print("Le nom d'utilisateur est vide.")
                return
            }
            
            FirebaseUser.shared.sendFriendRequest(username: username) { result in
                switch result {
                case .success():
                    print("Ami demandé avec succès")
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Erreur : \(error.localizedDescription)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Annuler", style: .cancel, handler: nil)
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        self.activeAlert = alertController
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    
    
}



extension FriendsVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isShowingFriendRequests {
            return friendRequests.count
        }else{
            return friends.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as! CustomCell
        
        if isShowingFriendRequests {
            if indexPath.row < friendRequests.count {
                let friendUsername = Array(friendRequests.values)[indexPath.row]
                
                if let label = cell.label {
                    label.text = friendUsername
                } else {
                    fatalError("Label is nil.")
                }
                cell.addButton?.isHidden = !isShowingFriendRequests
                cell.delegate = self
            } else {
                fatalError("IndexPath is out of bounds.")
            }
            
        }else{
            if indexPath.row < friends.count {
                let friendUsername = Array(friends.values)[indexPath.row]
                if let label = cell.label {
                    label.text = friendUsername
                } else {
                    fatalError("Label is nil.")
                }
                
                cell.addButton?.isHidden = !isShowingFriendRequests
                cell.delegate = self
            } else {
                // Gérez l'erreur ici
                fatalError("IndexPath is out of bounds.")
            }
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 50.0 // Remplacer par la hauteur désirée
        }
}


extension FriendsVC: CustomCellDelegate {
    
    
    func didTapAddButton(in cell: CustomCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let friendUID = Array(friendRequests.keys)[indexPath.row]
            let friendUsername = Array(friendRequests.values)[indexPath.row]
            // Ajouter l'ami à la liste d'amis ou effectuer d'autres actions avec l'UID de l'ami
            FirebaseUser.shared.acceptFriendRequest(friendID: friendUID, friendUsername: friendUsername) { result in
                switch result {
                case .success():
                    self.loadArrays()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func didTapRemoveButton(in cell: CustomCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        let friendUID : String?
        
        
        if isShowingFriendRequests {
            friendUID = Array(friendRequests.keys)[indexPath.row]
            if let friendUID = friendUID {
                FirebaseUser.shared.rejectFriendRequest(friendID: friendUID) { result in
                    switch result {
                    case .success:
                        self.loadArrays()
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        } else {
            friendUID = Array(friends.keys)[indexPath.row]
            if let friendUID = friendUID {
                FirebaseUser.shared.removeFriend(friendID: friendUID) { result in
                    switch result {
                    case .success:
                        self.loadArrays()
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}


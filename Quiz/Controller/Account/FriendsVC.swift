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
    
    var userListener: ListenerRegistration?
    
    @IBOutlet weak var switchControl: UISegmentedControl!
    
    
    @IBOutlet weak var tableView: UITableView!
    

    var usernames: [String] {
        if isShowingFriendRequests {
            return FirebaseUser.shared.fetchFriendRequests()
        } else {
            return FirebaseUser.shared.fetchFriends()
        }
    }
    var isShowingFriendRequests = true
    
    override func viewDidLoad() {
        
        setupUserListener()
        onSwitch(switchControl)
    }
    
    
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
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func setupUserListener() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Aucun utilisateur connecté")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUserID)
        
        // Ajouter un listener sur le document utilisateur
        userListener = userRef.addSnapshotListener { (documentSnapshot, error) in
            if let error = error {
                print("Erreur lors de l'écoute des modifications de l'utilisateur: \(error.localizedDescription)")
                return
            }
            
            if documentSnapshot != nil {
                // Mettre à jour les données utilisateur localement
                FirebaseUser.shared.getUserInfo() { result in
                    switch result {
                    case .success(): self.onSwitch(self.switchControl)
                        print("fait")
                    case .failure(let error): print(error)
                    }
                    
                    
                }
            }
        }
    }
    
    
}



extension FriendsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as! CustomFriendCell
        
        // Configurez votre cellule avec les données de la demande d'ami
        if indexPath.row < usernames.count {
            let friendUID = usernames[indexPath.row]
            cell.username!.text = friendUID
            
            // Afficher ou masquer les boutons en fonction de isShowingFriendRequests
            cell.addButton.isHidden = !isShowingFriendRequests
            //            cell.removeButton.isHidden = !isShowingFriendRequests
            
            // Configurer les boutons et la délégation
            cell.delegate = self
            
            return cell
        } else {
            // Gérez l'erreur ici
            fatalError("IndexPath is out of bounds.")
        }
    }
}


extension FriendsVC: FriendTableViewCellDelegate {
    func didTapAddButton(in cell: CustomFriendCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let friendUID = usernames[indexPath.row]
            
            // Ajouter l'ami à la liste d'amis ou effectuer d'autres actions avec l'UID de l'ami
            FirebaseUser.shared.acceptFriendRequest(friendID: friendUID) { result in
                switch result {
                case .success():
                    print("Demande d'ami acceptée avec succès")
                    self.onSwitch(self.switchControl)
                case .failure(let error):
                    print("Erreur : \(error.localizedDescription)")
                }
            }
        }
    }
    
    func didTapRemoveButton(in cell: CustomFriendCell) {
        
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        
        let friendUID = usernames[indexPath.row]
        
        if isShowingFriendRequests {
            FirebaseUser.shared.rejectFriendRequest(friendID: friendUID) { result in
                switch result {
                case .success:
                    self.onSwitch(self.switchControl)
                case .failure(let error):
                    print("Erreur lors du rejet de la demande d'ami : \(error.localizedDescription)")
                }
            }
        } else {
            FirebaseUser.shared.removeFriend(friendID: friendUID) { result in
                switch result {
                case .success:
                    self.onSwitch(self.switchControl)
                case .failure(let error):
                    print("Erreur lors de la suppression de l'ami : \(error.localizedDescription)")
                }
            }
        }
    }
}


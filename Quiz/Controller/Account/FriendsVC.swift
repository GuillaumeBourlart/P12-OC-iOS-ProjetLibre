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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadArrays()
        setupUserListener()
        onSwitch(switchControl)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshTable), name: NSNotification.Name("DataUpdated"), object: nil)
    }
    
    @objc func refreshTable() {
        DispatchQueue.main.async {
            self.loadArrays()
            print("reloaded")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        userListener?.remove()
        userListener = nil
    }
    
    // Load friends array and friend requests array for displaying
    func loadArrays(){
        FirebaseUser.shared.fetchFriends { data, error in
            if let error = error {
                print(error)
            }
            if let data = data {
                self.friends = data
                self.tableView.reloadData()
            }
        }
        FirebaseUser.shared.fetchFriendRequests() { data, error in
            if let error = error {
                print(error)
            }
            if let data = data {
                self.friendRequests = data
                self.tableView.reloadData()
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
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // Set up a listener to get any changes in document
    func setupUserListener() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Aucun utilisateur connecté")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUserID)
        
        // add listener
        userListener = userRef.addSnapshotListener { (documentSnapshot, error) in
            if let error = error {
                print("Erreur lors de l'écoute des modifications de l'utilisateur: \(error.localizedDescription)")
                return
            }
            
            if documentSnapshot != nil {
                // update local data
                FirebaseUser.shared.getUserInfo() { result in
                    switch result {
                    case .success(): self.loadArrays()
                        print("fait")
                    case .failure(let error): print(error)
                    }
                    
                    
                }
            }
        }
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
            // Configurez votre cellule avec les données de la demande d'ami
            if indexPath.row < friendRequests.count {
                let friendUID = Array(friendRequests.keys)[indexPath.row]
                let friendUsername = Array(friendRequests.values)[indexPath.row]
                
                if let label = cell.label {
                    label.text = friendUsername
                } else {
                    // Gérez l'erreur ici
                    fatalError("Label is nil.")
                }
                // Appelez la méthode configure pour déterminer si les boutons doivent être affichés ou non
                cell.configure(isFriendCell: true, cellType: .none)
                // Afficher ou masquer les boutons en fonction de isShowingFriendRequests
                cell.addButton?.isHidden = !isShowingFriendRequests
                //            cell.removeButton.isHidden = !isShowingFriendRequests
                
                // Configurer les boutons et la délégation
                cell.delegate = self
                
                
            } else {
                // Gérez l'erreur ici
                fatalError("IndexPath is out of bounds.")
            }
            
        }else{
            // Configurez votre cellule avec les données de la demande d'ami
            if indexPath.row < friends.count {
                let friendUID = Array(friends.keys)[indexPath.row]
                let friendUsername = Array(friends.values)[indexPath.row]
                if let label = cell.label {
                    label.text = friendUsername
                } else {
                    // Gérez l'erreur ici
                    fatalError("Label is nil.")
                }
                
                // Appelez la méthode configure pour déterminer si les boutons doivent être affichés ou non
                cell.configure(isFriendCell: true, cellType: .none)
                // Afficher ou masquer les boutons en fonction de isShowingFriendRequests
                cell.addButton?.isHidden = !isShowingFriendRequests
                //            cell.removeButton.isHidden = !isShowingFriendRequests
                
                // Configurer les boutons et la délégation
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
    func didChangeSwitchValue(in cell: CustomCell, isOn: Bool) {
        
    }
    
    func didChangeSliderValue(in cell: CustomCell, value: Float) {
        
    }
    
    
    func didTapAddButton(in cell: CustomCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let friendUID = Array(friendRequests.keys)[indexPath.row]
            let friendUsername = Array(friendRequests.values)[indexPath.row]
            // Ajouter l'ami à la liste d'amis ou effectuer d'autres actions avec l'UID de l'ami
            FirebaseUser.shared.acceptFriendRequest(friendID: friendUID, friendUsername: friendUsername) { result in
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
                        self.onSwitch(self.switchControl)
                    case .failure(let error):
                        print("Erreur lors du rejet de la demande d'ami : \(error.localizedDescription)")
                    }
                }
            }
        } else {
            friendUID = Array(friends.keys)[indexPath.row]
            if let friendUID = friendUID {
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
}


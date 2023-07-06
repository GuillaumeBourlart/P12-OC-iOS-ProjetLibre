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
    var receivedFriendRequests: [String: String] = [:]
    var sentFriendRequests: [String: String] = [:]
    
    var isShowingReceivedFriendRequests = false
    var isShowingSentFriendRequests = false
    var activeAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshTable), name: NSNotification.Name("DataUpdated"), object: nil)
        
        // setup pull to refresh
        // Initialiser le UIRefreshControl
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
            // Ajouter le UIRefreshControl à votre UITableView
            tableView.refreshControl = refreshControl
    }
    
    @objc func refreshData(_ sender: Any) {
        // Chargez vos nouvelles données ici
        reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadArrays()
        onSwitch(switchControl)
        let attributesNormal = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let attributesSelected = [NSAttributedString.Key.foregroundColor: UIColor.black]

        switchControl.setTitleTextAttributes(attributesNormal, for: .normal)
        switchControl.setTitleTextAttributes(attributesSelected, for: .selected)
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
    
    func reloadData(){
        FirebaseUser.shared.getUserInfo { result in
            switch result {
            case .failure(let error): print(error)
            case .success(): self.loadArrays()
            }
            self.tableView.refreshControl?.endRefreshing()
        }
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
        FirebaseUser.shared.fetchFriendRequests(status: .received) { data, error in
            if let error = error {
                print(error)
            }
            if let data = data {
                DispatchQueue.main.async {
                    self.receivedFriendRequests = data
                    self.tableView.reloadData()
                }
                
            }
        }
        FirebaseUser.shared.fetchFriendRequests(status: .sent) { data, error in
            if let error = error {
                print(error)
            }
            if let data = data {
                DispatchQueue.main.async {
                    self.sentFriendRequests = data
                    self.tableView.reloadData()
                }
                
            }
        }
    }
    
    // Function called when switching UIsegmentedCotroll index
    @IBAction func onSwitch(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: isShowingReceivedFriendRequests = false
            isShowingSentFriendRequests = false
            self.tableView.reloadData()
            
        case 1: isShowingReceivedFriendRequests = true
            isShowingSentFriendRequests = false
            self.tableView.reloadData()
            
        case 2: isShowingReceivedFriendRequests = false
            isShowingSentFriendRequests = true
            self.tableView.reloadData()
            
        default:
            print("error")
        }
    }
    
    // Function called when player wants to add a friend
    @IBAction func addFriend(sender: UIButton){
        let alertController = UIAlertController(title: "Add a friend", message: "Enter the username", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Username"
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { (_) in
            guard let username = alertController.textFields?.first?.text, !username.isEmpty else {
                print("field is empty")
                return
            }
            
            FirebaseUser.shared.sendFriendRequest(username: username) { result in
                switch result {
                case .success():
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error : \(error.localizedDescription)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        self.activeAlert = alertController
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}



extension FriendsVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isShowingReceivedFriendRequests {
            return receivedFriendRequests.isEmpty ? 1 : receivedFriendRequests.count
        }else if isShowingSentFriendRequests {
            return sentFriendRequests.isEmpty ? 1 : sentFriendRequests.count
        }else{
            return friends.isEmpty ? 1 : friends.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var data: [String: String]
        if isShowingReceivedFriendRequests {
            data = receivedFriendRequests
        } else if isShowingSentFriendRequests {
            data = sentFriendRequests
        } else {
            data = friends
        }
        
        if data.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath) as! EmptyCell
            self.tableView.separatorStyle = .none
            cell.isUserInteractionEnabled = false
            return cell
        } else {
            self.tableView.separatorStyle = .singleLine
            let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as! CustomCell
            let username = Array(data.values)[indexPath.row]
            if let label = cell.label {
                label.text = username
            } else {
                fatalError("Label is nil.")
            }
            cell.addButton?.isHidden = !isShowingReceivedFriendRequests
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isShowingReceivedFriendRequests {
            return receivedFriendRequests.isEmpty ? tableView.bounds.size.height : 50.0
        }else if isShowingSentFriendRequests {
            return sentFriendRequests.isEmpty ? tableView.bounds.size.height : 50.0
        }else{
            return friends.isEmpty ? tableView.bounds.size.height : 50.0
        }
    }
}


extension FriendsVC: CustomCellDelegate {
    
    
    func didTapAddButton(in cell: CustomCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let friendUID = Array(receivedFriendRequests.keys)[indexPath.row]
            let friendUsername = Array(receivedFriendRequests.values)[indexPath.row]
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
        
        
        if isShowingReceivedFriendRequests {
            friendUID = Array(receivedFriendRequests.keys)[indexPath.row]
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
        }else if !isShowingSentFriendRequests, !isShowingReceivedFriendRequests {
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


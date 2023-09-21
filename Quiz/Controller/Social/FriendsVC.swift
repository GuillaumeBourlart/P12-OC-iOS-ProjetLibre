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
    
    var colorChangeAnimation: CABasicAnimation?
    var borderLayer: CALayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createAnimatio()
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshTable), name: NSNotification.Name("DataUpdated"), object: nil)
        
        // initiate pull to refresh
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor.clear
        refreshControl.subviews.first?.backgroundColor = UIColor.clear
            // Ajouter le UIRefreshControl à votre UITableView
            tableView.refreshControl = refreshControl
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
    
    // refresh data when user pull to refresh
    @objc func refreshData(_ sender: Any) {
        self.tableView.refreshControl?.endRefreshing()
        startColorChangeAnimation()
        // Chargez vos nouvelles données ici
        reloadData()
    }
    
    // create the color animation for pull to refresh
    func createAnimatio() {
        colorChangeAnimation = CABasicAnimation(keyPath: "backgroundColor")
        colorChangeAnimation?.fromValue = UIColor.blue.cgColor
        colorChangeAnimation?.toValue = UIColor.orange.cgColor
        colorChangeAnimation?.duration = 1.0
        colorChangeAnimation?.repeatCount = .infinity
        colorChangeAnimation?.autoreverses = true
    }
    
    // refresh the table when controller receive a notification
    @objc func refreshTable() {
        self.loadArrays()
    }
    
    // reload friends
    func reloadData(){
        FirebaseUser.shared.getUserInfo { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                switch result {
                case .failure(let error): print(error)
                case .success(): self.loadArrays()
                }
                
                self.stopColorChangeAnimation()
            }
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
    
    // start the color animation when user pull to refresh
    func startColorChangeAnimation() {
        if let animation = colorChangeAnimation {
            borderLayer = CALayer()
            guard let borderLayer = borderLayer else {return}
            borderLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 8.0)
            borderLayer.backgroundColor = UIColor.green.cgColor
            tableView.layer.addSublayer(borderLayer)
            borderLayer.add(animation, forKey: "colorChange")
        }
    }

    // stop the color animation
    func stopColorChangeAnimation() {
        borderLayer?.removeAnimation(forKey: "colorChange")
        borderLayer?.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 0.0)
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
        let alertTitle = NSLocalizedString("Add a friend", comment: "")
        let alertMessage = NSLocalizedString("Enter the username", comment: "")
        let addMessage = NSLocalizedString("Add", comment: "")
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Username"
        }
        
        let addAction = UIAlertAction(title: addMessage, style: .default) { (_) in
            guard let username = alertController.textFields?.first?.text, !username.isEmpty else {
                print("field is empty")
                return
            }
            
            FirebaseUser.shared.sendFriendRequest(username: username) { result in
                switch result {
                case .success():
                    self.loadArrays()
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error : \(error.localizedDescription)")
                }
            }
        }
        let cancelMessage = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelMessage, style: .cancel, handler: nil)
        
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
        }else if isShowingSentFriendRequests {
            friendUID = Array(sentFriendRequests.keys)[indexPath.row]
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

extension FriendsVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let emptyCell = tableView.visibleCells.first(where: { $0 is EmptyCell }) as? EmptyCell {
            let pullDistance = -tableView.contentOffset.y
            let scale = min(max(pullDistance / 50, 1.0), 10.0) // ici on divise par 50 au lieu de 100
            emptyCell.label.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
}

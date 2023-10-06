//
//  InvitesVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 24/05/2023.
//

import Foundation
import UIKit
import Firebase

// Controller to consult all invites
class InvitesVC: UIViewController {
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    // Properties
    var invites: [String: String] = [:] // Dictionary to store invites with usernames as keys and lobby IDs as values
    var colorChangeAnimation: CABasicAnimation? // Animation for changing background color during pull-to-refresh
    var borderLayer: CALayer?  // Layer for the pull-to-refresh color animation
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshTable), name: NSNotification.Name("DataUpdated"), object: nil)
        // setup pull to refresh
        createAnimatio()
        // initiate UIRefreshControl
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor.clear
        refreshControl.subviews.first?.backgroundColor = UIColor.clear
        // add UIRefresh to the table
        tableView.refreshControl = refreshControl
    }
    
    // Method called when view will appear
    override func viewWillAppear(_ animated: Bool) {
        // load invites
        fetchInvites()
    }
    
    
    // Refresh invites when user pull to refresh
    @objc func refreshData(_ sender: Any) {
        self.tableView.refreshControl?.endRefreshing()
        startColorChangeAnimation()
        
        // refresh invites
        loadInvites()
    }
    
    // Refresh invites when the controller receive the Notification
    @objc func refreshTable() {
        DispatchQueue.main.async {
            self.loadInvites()
        }
    }
    
    // function to reload invites
    func loadInvites() {
        FirebaseUser.shared.getUserInfo { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                switch result {
                case .failure(let error): print(error)
                case .success():
                    self.fetchInvites()
                }
                // stop the color animation
                self.stopColorChangeAnimation()
                
            }
        }
    }
    
    // create the color animation
    func createAnimatio() {
        colorChangeAnimation = CABasicAnimation(keyPath: "backgroundColor")
        colorChangeAnimation?.fromValue = UIColor.green.cgColor
        colorChangeAnimation?.toValue = UIColor.red.cgColor
        colorChangeAnimation?.duration = 1.0
        colorChangeAnimation?.repeatCount = .infinity
        colorChangeAnimation?.autoreverses = true
    }
    
    // animate the top border in multicolor
    func startColorChangeAnimation() {
        if let animation = colorChangeAnimation {
            // Create layer for the border
            borderLayer = CALayer()
            guard let borderLayer = borderLayer else {return}
            borderLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 8.0)
            borderLayer.backgroundColor = UIColor.green.cgColor
            // Add the layer to tableView
            tableView.layer.addSublayer(borderLayer)
            
            borderLayer.add(animation, forKey: "colorChange")
        }
    }
    
    // stop the color change animation
    func stopColorChangeAnimation() {
        borderLayer?.removeAnimation(forKey: "colorChange")
        borderLayer?.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 0.0)
        
    }
    
    // function that fetch invites
    func fetchInvites() {
        FirebaseUser.shared.fetchInvites { data, error in
            if let error = error {
                print(error)
            }
            if let data = data {
                self.invites = data
                self.tableView.reloadData()
            }
            
        }
    }
    
    // Prepare for the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PrivateLobbyVC {
            destination.lobbyId = sender as? String
            destination.isCreator = false
        }
    }
    
    // function to join a lobby from the tapped invite
    func joinLobby(lobbyId: String) {
        // delete the invite after user clicked on it
        Game.shared.deleteInvite(inviteId: lobbyId) { result in
            switch result {
            case .failure(let error): print(error)
            case .success(let lobbyID): print("invite \(lobbyID) deleted")
                self.fetchInvites()
            }
        }
        // Try to join the room linked to the invite
        Game.shared.joinRoom(lobbyId: lobbyId){ result in
            switch result {
            case .failure(let error): print(error)
                if let tabBar = self.tabBarController as? CustomTabBarController {
                    tabBar.showSessionExpiredAlert()
                }
            case .success():
                self.performSegue(withIdentifier: "goToPrivateLobby", sender: lobbyId)
            }
        }
        
    }
    
    // Unwind segue action method
    @IBAction func unwindToInvites(segue: UIStoryboardSegue) {
    }
    
    
}

// UITableViewDelegate methods
extension InvitesVC: UITableViewDelegate {
    // Set the height for table view cells based on data or a default value
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return invites.isEmpty ? tableView.bounds.size.height : 70.0
    }
    
    // Handle selection of a table view cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Retrieve the selected invite and join the lobby
        let selectedInvite = Array(invites)[indexPath.row]
        self.joinLobby(lobbyId: selectedInvite.value)
    }
}

// UITableViewDataSource methods
extension InvitesVC: UITableViewDataSource {
    // Return the number of rows in the table view based on data or a default value
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invites.isEmpty ? 1 : invites.count
    }
    
    // Create and configure table view cells based on data or a default empty cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if invites.isEmpty {
            // Create an empty cell with a "Pull to refresh" message
            let emptyCell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath) as! EmptyCell
            emptyCell.label.text = NSLocalizedString("Pull to refresh", comment: "")
            self.tableView.separatorStyle = .none
            emptyCell.isUserInteractionEnabled = false
            return emptyCell
        } else {
            self.tableView.separatorStyle = .singleLine
            
            // Create and configure a custom cell with invite information
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
            let invite = Array(invites)[indexPath.row]
            let userText = NSLocalizedString("Invite from", comment: "")
            cell.label.text = userText + " : \(invite.key)"
            
            // Create the disclosure indicator for the cell
            cell.accessoryType = .disclosureIndicator
            
            return cell
        }
    }
}

// UIScrollViewDelegate method
extension InvitesVC: UIScrollViewDelegate {
    // Handle scrolling in the table view to transform an empty cell's label
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let emptyCell = tableView.visibleCells.first(where: { $0 is EmptyCell }) as? EmptyCell {
            let pullDistance = -tableView.contentOffset.y
            let scale = min(max(pullDistance / 50, 1.0), 10.0)
            emptyCell.label.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
}

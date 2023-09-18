//
//  InvitesVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 24/05/2023.
//

import Foundation
import UIKit
import Firebase

class InvitesVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var invites: [String: String] = [:]
    var colorChangeAnimation: CABasicAnimation?
    var borderLayer: CALayer?
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        // load invites
        loadInvites()
    }
    
    
    // Refresh invites when user pull to refresh
    @objc func refreshData(_ sender: Any) {
        self.tableView.refreshControl?.endRefreshing()
        if tableView.visibleCells.first(where: { $0 is EmptyCell }) is EmptyCell {
               startColorChangeAnimation()
           }
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
                if self.tableView.visibleCells.first(where: { $0 is EmptyCell }) is EmptyCell {
                    self.stopColorChangeAnimation()
                }
            }
        }
    }
    
    // create the color animation
    func createAnimatio() {
        // Création de l'animation de couleur
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
            // Créez le layer pour la bordure en haut
            borderLayer = CALayer()
            guard let borderLayer = borderLayer else {return}
            borderLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 8.0)
            borderLayer.backgroundColor = UIColor.green.cgColor

            // Ajoutez le layer à la vue
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
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PrivateLobbyVC {
            destination.lobbyId = sender as? String
            destination.isCreator = false
        }
    }
    
    // function to join a lobby from the tapped invite
    func joinLobby(lobbyId: String) {
        Game.shared.joinRoom(lobbyId: lobbyId){ result in
            switch result {
            case .failure(let error): print(error)
            case .success():
                self.performSegue(withIdentifier: "goToPrivateLobby", sender: lobbyId)
            }
        }
    }
    
    @IBAction func unwindToInvites(segue: UIStoryboardSegue) {
        // Vous pouvez utiliser cette méthode pour effectuer des actions lorsque l'unwind segue est exécuté.
    }
    
    
}


extension InvitesVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return invites.isEmpty ? tableView.bounds.size.height : 70.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedInvite = Array(invites)[indexPath.row]
        self.joinLobby(lobbyId: selectedInvite.value)
    }
}

extension InvitesVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invites.isEmpty ? 1 : invites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if invites.isEmpty {
            let emptyCell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath) as! EmptyCell
            emptyCell.label.text = NSLocalizedString("Pull to refresh", comment: "")
            self.tableView.separatorStyle = .none
            emptyCell.isUserInteractionEnabled = false
            return emptyCell
        } else {
            self.tableView.separatorStyle = .singleLine
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
            let invite = Array(invites)[indexPath.row]
            let userText = NSLocalizedString("User", comment: "")
            let lobbyText = NSLocalizedString("Lobby", comment: "")
            cell.label.text = userText + ": \(invite.key) - " + lobbyText + invite.value

            // create the disclosure indicator
            let whiteDisclosureIndicator = UIImageView(image: UIImage(systemName: "chevron.right"))
            whiteDisclosureIndicator.tintColor = .white
            whiteDisclosureIndicator.backgroundColor = UIColor.clear
            whiteDisclosureIndicator.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
            cell.accessoryView = whiteDisclosureIndicator
            return cell
        }
    }
}


extension InvitesVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let emptyCell = tableView.visibleCells.first(where: { $0 is EmptyCell }) as? EmptyCell {
            let pullDistance = -tableView.contentOffset.y
            let scale = min(max(pullDistance / 50, 1.0), 10.0) // ici on divise par 50 au lieu de 100
            emptyCell.label.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
}

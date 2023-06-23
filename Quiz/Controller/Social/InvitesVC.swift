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
    
    override func viewDidLoad() {
            super.viewDidLoad()
            NotificationCenter.default.addObserver(self, selector: #selector(self.refreshTable), name: NSNotification.Name("DataUpdated"), object: nil)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            loadInvites()
        }
        
        @objc func refreshTable() {
            DispatchQueue.main.async {
                self.loadInvites()
            }
        }
        
        func loadInvites() {
            FirebaseUser.shared.getUserInfo { result in
                switch result {
                case .failure(let error): print(error)
                case .success():
                    self.fetchInvites()
                }
            }
        }

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
            return 70.0 // Remplacer par la hauteur désirée
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedInvite = Array(invites)[indexPath.row]
        self.joinLobby(lobbyId: selectedInvite.value)
    }
}

extension InvitesVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
        
        let invite = Array(invites)[indexPath.row]
        cell.label.text = "User: \(invite.key) - Lobby: \(invite.value)"
        
        let whiteDisclosureIndicator = UIImageView(image: UIImage(systemName: "chevron.right"))
        whiteDisclosureIndicator.tintColor = .white // Remplacez "customDisclosureIndicator" par le nom de votre image.
        whiteDisclosureIndicator.backgroundColor = UIColor.clear
        whiteDisclosureIndicator.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
        cell.accessoryView = whiteDisclosureIndicator
        
        return cell
    }
}

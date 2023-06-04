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
    
    var listener : ListenerRegistration? = nil
    var invites: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        startListening()
        loadInvites()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        listener = nil
    }
    
    func loadInvites(){
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
    
    func startListening() {
        guard let currentUserId = Game.shared.currentUserId else {
            return
        }
        listener = Game.shared.ListenForChangeInDocument(in: "users", documentId: currentUserId) { result in
            switch result {
            case .success(let data):
                print("cece")
                if let invites = data["invites"] as? [String: String] {
                    if FirebaseUser.shared.userInfo != nil {
                        FirebaseUser.shared.userInfo!.invites = invites
                        self.loadInvites()
                    }
                }
                
                // Handle the updated data...
            case .failure(let error):
                print(error)
                // Handle the error...
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PrivateLobbyVC{
            destination.lobbyId = sender as? String
            destination.isCreator = false
        }
    }
    
    func joinLobby(lobbyId: String){
        Game.shared.joinRoom(lobbyId: lobbyId){ result in
            switch result {
            case .failure(let error): print(error)
            case .success():
                Game.shared.deleteInvite(inviteId: lobbyId) { result in
                switch result {
                    case .failure(let error): print(error)
                    case .success(let inviteID): self.performSegue(withIdentifier: "goToPrivateLobby", sender: inviteID)
                    }
                }
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
        
        return cell
    }
}

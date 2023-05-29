//
//  PrivateLobby.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 24/05/2023.
//

import Foundation
import UIKit
import Firebase


class PrivateLobbyVC: UIViewController{
    var lobbyId: String?
    
    @IBOutlet weak var joinCodeLabel: UILabel!
    
    
    @IBOutlet weak var leave: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var invteplayersButton: UIButton!
    
    @IBOutlet weak var launchButton: CustomButton!
    var isCreator: Bool?
    var invitedPlayers: [String] = []
    var invitedGroups: [String] = []
    var players: [String] = []
    var listener: ListenerRegistration? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        if isCreator! {
            joinCodeLabel.isHidden = false
            invteplayersButton.isHidden = false
            launchButton.isHidden = false
        }else{
            startListeningForbegin()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let lobbyId = lobbyId {
            startListening(lobbyId: lobbyId)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let listener = listener {
            listener.remove()
        }
        Game.shared.leaveLobby(lobbyId: lobbyId!) { error in
            if let error = error {
                print(error)
            }
            
        }
    }
    
    @IBAction func leaveLobbyWasPressed(_ sender: Any) {
        Game.shared.leaveLobby(lobbyId: lobbyId!) { error in
            if let error = error {
                print(error)
                return
            }
            if self.isCreator != nil, self.isCreator == true {
                Game.shared.deleteCurrentRoom { result in
                    switch result {
                    case .failure(let error): print(error)
                    case .success(): print("lobby supprimé")
                       
                    }
                }
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    @IBAction func InvitePlayersButtonPeressed(_ sender: UIButton) {
        performSegue(withIdentifier: "goToInvitePlayers", sender: sender)
    }
    
    @IBAction func launchGame(){
        Game.shared.createGame(competitive: false, players: self.players) { result in
            switch result {
            case .failure(let error): print(error)
            case .success(let gameID): self.performSegue(withIdentifier: "goToQuizz", sender: gameID)
            }
        }
    }
    
    func startListening(lobbyId: String) {
        listener = Game.shared.ListenForChangeInDocument(in: "lobby", documentId: lobbyId, completion: { result in
            switch result {
            case .success(let data):
                if let players = data["players"] as? [String] {
                    self.players = players
                }
                if let invitedPlayers = data["invited_users"] as? [String] {
                    self.invitedPlayers = invitedPlayers
                }
                if let code = data["join_code"] as? String {
                    self.joinCodeLabel.text = code
                }
                self.tableView.reloadData()
            case .failure(let error): print(error)
                self.navigationController?.popViewController(animated: true)
            }
        })
    }
    
    func startListeningForbegin() {
        listener = Game.shared.ListenForGameLaunch() { [weak self] result in
            switch result {
            case .success(let gameId):
                print("Game found: \(gameId)")
                self?.performSegue(withIdentifier: "goToQuizz", sender: gameId)
            case .failure(let error):
                print("Error fetching game: \(error)")
            }
        }
    }
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? InvitePlayersVC {
            destination.lobbyID = lobbyId
        }else if let destination = segue.destination as? QuizzVC {
            destination.gameID = sender as? String
        }
    }
    
    
}

extension PrivateLobbyVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2  // one for players, another for invitedPlayers
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return players.count
        } else  {
            return invitedPlayers.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? CustomCell else { return UITableViewCell() }
        if indexPath.section == 0 {
            cell.label.text = players[indexPath.row]
        } else {
            cell.label.text = invitedPlayers[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Current Players"
        } else {
            return "Invited Players"
        }
    }
}





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
    var difficulty: String?
    var category: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: true)
            tabBarController?.tabBar.isHidden = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let lobbyId = lobbyId {
            startListening(lobbyId: lobbyId)
            
            if isCreator! {
                joinCodeLabel.isHidden = false
                invteplayersButton.isHidden = false
                launchButton.isHidden = false
            }else{
                startListeningForbegin()
            }
        }
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = false
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
                Game.shared.deleteCurrentRoom(lobbyId: self.lobbyId!) { result in
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
        Game.shared.createGame(category: category, difficulty: difficulty, with: lobbyId, competitive: false, players: self.players) { result in
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
        listener = Game.shared.ListenForChangeInDocument(in: "games", documentId: lobbyId!) { result in
            switch result {
            case .success(let gamedata):
                if let gameID = gamedata["id"], let status = gamedata["status"] as? String , status == "waiting" {
                    self.performSegue(withIdentifier: "goToQuizz", sender: gameID)
                }
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
            destination.isCompetitive = false
        }
    }
    
    
}

extension PrivateLobbyVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()

            let headerLabel = UILabel(frame: CGRect(x: 15, y: 0, width:
                tableView.bounds.size.width, height: tableView.sectionHeaderHeight))
            headerLabel.font = UIFont(name: "Helvetica", size: 18)
            headerLabel.textColor = UIColor.white  // couleur du texte
            headerLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
            headerLabel.sizeToFit()
            headerView.addSubview(headerLabel)

            return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 70.0 // Remplacer par la hauteur désirée
        }
    
    
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





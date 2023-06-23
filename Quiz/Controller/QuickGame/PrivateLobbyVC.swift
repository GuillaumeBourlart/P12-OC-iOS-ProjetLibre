//
//  PrivateLobby.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 24/05/2023.
//

import Foundation
import UIKit
import Firebase


class PrivateLobbyVC: UIViewController, LeavePageProtocol{
    
    @IBOutlet weak var joinCodeLabel: UILabel!
    @IBOutlet weak var leave: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var invteplayersButton: UIButton!
    @IBOutlet weak var launchButton: CustomButton!
    
    var lobbyId: String?
    var isCreator: Bool?
    var invitedPlayers: [String] = []
    var invitedGroups: [String] = []
    var players: [String] = []
    var listener: ListenerRegistration? = nil
    var difficulty: String?
    var category: Int?
    var quizId: String?
    var usernamesForUIDs = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Cacher le bouton retour
        self.navigationItem.hidesBackButton = true
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let lobbyId = lobbyId {
            startListening(lobbyId: lobbyId)
            guard let isCreator = isCreator else { return }
            if isCreator {
                joinCodeLabel.isHidden = false
                invteplayersButton.isHidden = false
                launchButton.isHidden = false
            }
        }
        
        getUsernames()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let listener = listener {
            listener.remove()
        }
        self.navigationItem.hidesBackButton = false
        tabBarController?.tabBar.isHidden = false
    }
    
    // Function that get usernames to display usernames rather than UIDs
    func getUsernames(){
        let allPlayerUIDs = players + invitedPlayers
        FirebaseUser.shared.getUsernames(with: allPlayerUIDs) { [weak self] result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let usernamesDict):
                self?.usernamesForUIDs = usernamesDict
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        }
        
        
    }
    
    func showLeaveConfirmation(completion: @escaping () -> Void) {
        let alert = UIAlertController(title: "Confirmation", message: "Êtes-vous sûr de vouloir quitter le quiz ?", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Oui", style: .destructive) { _ in
            completion()
        }
        let cancelAction = UIAlertAction(title: "Non", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true)
    }
    
    // Function called when user click on "leave" button
    @IBAction func leaveLobbyWasPressed(_ sender: Any) {
        showLeaveConfirmation {
            self.leaveLobby() {error in
                if let error = error {
                    print(error)
                }
            }
        }
    }
    
    // Function called by appdelegate when user click on notification
    func leavePage(completion: @escaping () -> Void) {
        showLeaveConfirmation {
            self.leaveLobby() { error in
                if let error = error {
                    print(error)
                }
                completion()
            }
        }
    }
    
    // Function to leave the lobby
    func leaveLobby(completion: @escaping (Error?) -> Void) {
        self.leave.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: self.leave) {
            guard let lobbyId = self.lobbyId else { return }
            Game.shared.leaveLobby(lobbyId: lobbyId) { error in
                if let error = error {
                    completion(error)
                    self.leave.isEnabled = true
                    self.navigationController?.popViewController(animated: true)
                    return
                }
                // If user is the creator of the lobby, destroy it
                else if self.isCreator != nil, self.isCreator == true {
                    Game.shared.deleteCurrentRoom(lobbyId: lobbyId) { result in
                        switch result {
                        case .failure(let error):
                            self.leave.isEnabled = true
                            completion(error)
                        case .success():
                            self.leave.isEnabled = true
                            self.navigationController?.popViewController(animated: true)
                            completion(nil)
                            
                        }
                    }
                }else{
                    self.navigationController?.popViewController(animated: true)
                    completion(nil)
                }
                
            }
        }
        
    }
    
    // Function to go on inviting page
    @IBAction func InvitePlayersButtonPeressed(_ sender: UIButton) {
        performSegue(withIdentifier: "goToInvitePlayers", sender: sender)
    }
    
    // Functin to launch the game
    @IBAction func launchGame(){
        CustomAnimations.buttonPressAnimation(for: self.launchButton) {
            self.launchButton.isEnabled = false
            Game.shared.createQuestionsForGame(quizId: self.quizId ,category: self.category, difficulty: self.difficulty, with: self.lobbyId, competitive: false, players: self.players) { result in
                switch result {
                case .failure(let error): print(error)
                    self.launchButton.isEnabled = true
                case .success: print("succes")
                    
                }
            }
        }
        
    }
    
    
    // Function that listen for change in lobby document
    func startListening(lobbyId: String) {
        listener = Game.shared.ListenForChangeInDocument(in: "lobby", documentId: lobbyId, completion: { result in
            switch result {
            case .success(let data):
                
                guard let playersDict = data["players"] as? [String] else { self.navigationController?.popViewController(animated: true); return }
                guard let invitedPlayersDict = data["invited_users"] as? [String] else { self.navigationController?.popViewController(animated: true); return }
                guard let code = data["join_code"] as? String else { self.navigationController?.popViewController(animated: true); return }
                
                self.players = playersDict
                self.invitedPlayers = invitedPlayersDict
                self.joinCodeLabel.text = code
                
                self.getUsernames()
                
                // If game is started, check if game exist
                if let status = data["status"] as? String, status == "started" {
                    self.checkIfGameExist(lobbyId: lobbyId)
                    
                }
                
            case .failure(let error):
                print(error)
                self.navigationController?.popViewController(animated: true)
            }
        })
    }
    
    // Function that check if game exists
    func checkIfGameExist(lobbyId: String) {
        Game.shared.checkIfGameExist(gameID: lobbyId) { result in
            switch result {
            case .success(let gameId):
                print("gameID : \(gameId)")
                self.performSegue(withIdentifier: "goToQuizz", sender: gameId)
                self.launchButton.isEnabled = true
            case .failure(let error):
                print("Error fetching game: \(error)")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? InvitePlayersVC {
            destination.lobbyID = lobbyId
        }else if let destination = segue.destination as? GameVC {
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
        return 50.0 // Remplacer par la hauteur désirée
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
        var uid = ""
        if indexPath.section == 0 {
            uid = players[indexPath.row]
        } else {
            uid = invitedPlayers[indexPath.row]
        }
        // Use the username if available, otherwise use the UID
        cell.label.text = usernamesForUIDs[uid] ?? uid
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



//
//  PrivateLobby.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 24/05/2023.
//

import Foundation
import UIKit
import Firebase

// Class for private room 
class PrivateLobbyVC: UIViewController, LeavePageProtocol{
    // Outlets
    @IBOutlet weak var joinCodeLabel: UILabel!
    @IBOutlet weak var leave: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var invteplayersButton: UIButton!
    @IBOutlet weak var launchButton: CustomButton!
    // Properties
    var lobbyId: String? // ID of the lobby
       var isCreator: Bool? // Indicates if the user is the creator of the lobby
       var invitedPlayers: [String] = [] // List of invited player UIDs
       var invitedGroups: [String] = [] // List of invited groups
       var players: [String] = [] // List of current players in the lobby
       var listener: ListenerRegistration? = nil // Listener registration for Firebase
       var difficulty: String? // Difficulty level of the game
       var category: Int? // Category of the game
       var quizId: String? // ID of the quiz
       var usernamesForUIDs = [String: String]() // Dictionary for mapping UIDs to usernames
       var activeAlert: UIAlertController? // Active alert for confirmation
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // Method called when the view will appear
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
            
            // If an alert is being displayed, dismiss it
            if let activeAlert = activeAlert {
                activeAlert.dismiss(animated: false)
                self.activeAlert = nil
            }
            
            self.navigationItem.hidesBackButton = true
            tabBarController?.tabBar.isHidden = true
        }
    
    // Method called when the view will disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let listener = listener {
            listener.remove()
        }
        self.navigationItem.hidesBackButton = false
        tabBarController?.tabBar.isHidden = false
    }
    
    // Function that gets usernames to display usernames rather than UIDs
    func getUsernames() {
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
    
    // Alert shown before to leave the lobby
    func showLeaveConfirmation(completion: @escaping () -> Void) {
        let alert = UIAlertController(title: NSLocalizedString("Confirmation", comment: ""), message: NSLocalizedString("Are you sure you want to leave the room?", comment: ""), preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .destructive) { _ in
            completion()
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        self.activeAlert = alert
        
        self.present(alert, animated: true)
    }
    
    // Function called when user click on "leave" button
    @IBAction func leaveLobbyWasPressed(_ sender: Any) {
        showLeaveConfirmation {
            self.leaveLobby() {result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success():
                    print("success")
                }
            }
        }
    }
    
    // Function called by appdelegate when user click on notification
    func leavePage(completion: @escaping () -> Void) {
        showLeaveConfirmation {
            self.leaveLobby() {result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success():
                    print("success")
                    completion()
                }
            }
        }
    }
    
    // Function to leave lobby
    func leaveLobby(completion: @escaping (Result<Void, Error>) -> Void) {
        self.leave.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: self.leave) {
            
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            
            guard let lobbyId = self.lobbyId else { return }
            Game.shared.leaveLobby(lobbyId: lobbyId) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                    self.leave.isEnabled = true
                    self.navigationController?.popViewController(animated: true)
                case .success():
                    // If user is the creator of the lobby, destroy it
                    if self.isCreator != nil, self.isCreator == true {
                        Game.shared.deleteCurrentRoom(lobbyId: lobbyId) { result in
                            switch result {
                            case .failure(let error):
                                self.leave.isEnabled = true
                                completion(.failure(error))
                            case .success():
                                self.leave.isEnabled = true
                                self.navigationController?.popViewController(animated: true)
                                completion(.success(()))
                            }
                        }
                    } else {
                        self.navigationController?.popViewController(animated: true)
                        completion(.success(()))
                    }
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
            
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            
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
    
    // Called before the segue
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
    
    // Function to provide a custom view for the section header in the table view
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        
        // Create a label for the section header
        let headerLabel = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.bounds.size.width, height: tableView.sectionHeaderHeight))
        headerLabel.font = UIFont(name: "Helvetica", size: 18) // Set the font and size for the header label
        headerLabel.textColor = UIColor(named: "text")  // Set the text color using a named color
        headerLabel.text = self.tableView(tableView, titleForHeaderInSection: section) // Set the header text
        headerLabel.sizeToFit()
        
        // Add the header label to the header view
        headerView.addSubview(headerLabel)
        
        return headerView
    }
    
    // Function to specify the height for each row in the table view
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0 // Replace with the desired height for table view rows
    }
    
    // Function to specify the number of sections in the table view
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2  // There are two sections: one for players, another for invited players
    }
    
    // Function to specify the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return players.count // Number of rows in the "Current Players" section
        } else  {
            return invitedPlayers.count // Number of rows in the "Invited Players" section
        }
    }
    
    // Function to configure and return a cell for a given row and section
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue a reusable cell with the identifier "Cell" and cast it to CustomCell
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? CustomCell else { return UITableViewCell() }
        var uid = ""
        if indexPath.section == 0 {
            uid = players[indexPath.row] // Get the UID for the current player row
        } else {
            uid = invitedPlayers[indexPath.row] // Get the UID for the invited player row
        }
        // Use the username if available, otherwise use the UID as the text for the cell label
        cell.label.text = usernamesForUIDs[uid] ?? uid
        return cell
    }
    
    // Function to specify the title for each section header
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("Current Players", comment: "") // Title for the "Current Players" section
        } else {
            return NSLocalizedString("Invited Players", comment: "") // Title for the "Invited Players" section
        }
    }
}




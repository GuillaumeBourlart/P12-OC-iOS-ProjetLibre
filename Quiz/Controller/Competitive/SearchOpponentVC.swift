//
//  SearchOpponent.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 22/04/2023.
//

import Foundation
import FirebaseFirestore
// Controller to search a new ranked opponent
class SearchOpponentVC: UIViewController, LeavePageProtocol{
    // Properties
    var lobbyId: String? // Current lobby (found or created)
    var listener: ListenerRegistration? = nil // Listener to know if someone join the created lobby
    var isCancelSearchCalled = false // set to true if search is cancelled
    var gameFound = false // set to true if a game is found
    
    // Method called when view is loaded
    override func viewDidLoad() {
        tabBarController?.tabBar.isHidden = true
        super.viewDidLoad()
        findOpponent()
    }
    
    // Method called when view will appear
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    // Method called when view will disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let listener = listener {
            listener.remove()
        }
        if !isCancelSearchCalled, !gameFound {
            cancelSearch { error in
                if let error = error {
                    print(error)
                }
            }
        }
        
        tabBarController?.tabBar.isHidden = false
    }
    
    // Fonction called by appdelegate when user click on a notification so he stop looking for a new opponent
    func leavePage(completion: @escaping () -> Void) {
        cancelSearch { error in
            if let error = error {
                print(error)
                
            }
            self.dismiss(animated: true) {
                completion()
            }
        }
    }
    
    // fonction to cancel the search
    func cancelSearch(completion: @escaping (Error?) -> Void){
        if !gameFound {
            guard let lobbyId = lobbyId else { return }
            Game.shared.deleteCurrentRoom(lobbyId: lobbyId){ result in
                switch result {
                case .success():
                    completion(nil)
                    self.lobbyId = nil
                    self.isCancelSearchCalled = true
                case .failure(let error):
                    completion(error)
                }
            }
        }
    }
    
    // Fonction to begin opponent's search
    func findOpponent() {
        Game.shared.searchCompetitiveRoom(){ result in
            switch result {
            case .success(let lobbyId): self.lobbyId = lobbyId
                self.startListening()
            case .failure(let error):
                print(error.localizedDescription.description)
            }
        }
        
    }
    
    // Fonction to listen if game is created (with same id than the lobby ID)
    func startListening() {
        guard let lobbyId = lobbyId else { return }
        listener = Game.shared.ListenForChangeInDocument(in: "games", documentId: lobbyId) { result in
            switch result {
            case .success(let gamedata):
                if let gameID = gamedata["id"] {
                    self.gameFound = true
                    self.performSegue(withIdentifier: "goToQuizz", sender: gameID)
                }
            case .failure(let error):
                print("Error fetching game: \(error)")
            }
        }
    }
    
    // Called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? GameVC {
            destination.gameID = sender as? String
            destination.isCompetitive = true
        }
    }
    
    
}

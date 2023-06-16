//
//  SearchOpponent.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 22/04/2023.
//

import Foundation
import FirebaseFirestore

class SearchOpponentVC: UIViewController, LeavePageProtocol{
    
    var lobbyId: String?
    var listener: ListenerRegistration? = nil
    var isGameFound = false
    var isCancelSearchCalled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        findOpponent()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if let listener = listener {
                listener.remove()
            }
            if !isCancelSearchCalled {
                cancelSearch { error in
                    if let error = error {
                        print(error)
                    }
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    
    // Fonction called by appdelegate when user click on a notification
    func leavePage(completion: @escaping () -> Void) {
        cancelSearch { error in
            if let error = error {
                print(error)
                
            }
            self.dismiss(animated: true) {
                // Call the completion closure after the page has been dismissed
                completion()
            }
        }
    }
    
    // fonction to cancel the search
    func cancelSearch(completion: @escaping (Error?) -> Void){
        if !isGameFound {
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
    
    // Fonction to listen for new opponent found
    func startListening() {
        guard let lobbyId = lobbyId else { return }
        listener = Game.shared.ListenForChangeInDocument(in: "games", documentId: lobbyId) { result in
            switch result {
            case .success(let gamedata):
                if let gameID = gamedata["id"] {
                    self.performSegue(withIdentifier: "goToQuizz", sender: gameID)
                }
            case .failure(let error):
                print("Error fetching game: \(error)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QuizzVC {
            destination.gameID = sender as? String
            destination.isCompetitive = true
        }
    }
    
   
}

//
//  SearchOpponent.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 22/04/2023.
//

import Foundation
import FirebaseFirestore

class SearchOpponentVC: UIViewController{
    
    var lobbyId: String?
    var listener: ListenerRegistration? = nil
    var isGameFound = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        findOpponent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let listener = listener {
            listener.remove()
        }
        
        if !isGameFound {
            Game.shared.deleteCurrentRoom(lobbyId: lobbyId!){ result in
                switch result {
                case .success():
                    print("annulation réussie")
                case .failure(let error):
                    print(error.localizedDescription.description)
                }
            }
        }
    }
    
    func findOpponent() {
        Game.shared.searchCompetitiveRoom(){ result in
            switch result {
            case .success(let lobbyId): self.lobbyId = lobbyId
                print("recherche réussie ")
                self.startListening()
            case .failure(let error):
                print(error.localizedDescription.description)
            }
        }
        
    }
    
    func startListening() {
        listener = Game.shared.ListenForChangeInDocument(in: "games", documentId: lobbyId!) { result in
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

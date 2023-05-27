//
//  SearchOpponent.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 22/04/2023.
//

import Foundation
import FirebaseFirestore

class SearchOpponentVC: UIViewController{
    
    var listener: ListenerRegistration? = nil
    
    var isGameFound = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startListening()
        findOpponent()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let listener = listener {
            listener.remove()
        }
        
        if !isGameFound {
            Game.shared.deleteCurrentLobby(){ result in
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
        
        Game.shared.searchCompetitiveLobby(){ result in
            switch result {
            case .success:
                print("recherche réussie ")
            case .failure(let error):
                print(error.localizedDescription.description)
            }
        }
        
    }
    
    
    
    func startListening() {
        listener = Game.shared.ListenForGameFound() { [weak self] result in
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
        if let destination = segue.destination as? QuizzVC {
            destination.gameID = sender as? String
        }
    }
    
   
}

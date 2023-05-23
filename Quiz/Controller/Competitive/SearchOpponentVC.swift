//
//  SearchOpponent.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 22/04/2023.
//

import Foundation
import FirebaseFirestore

class SearchOpponentVC: UIViewController{
    var listener: ListenerRegistration?
    
    var timer: Timer?
    var isGameFound = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        findOpponent()
        listenForGameStart()
        startTimer()
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
        
        timer?.invalidate()
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
    
    func listenForGameStart() {
        Game.shared.listenForGameStart { result in
            switch result {
            case .success(let gameId):
                self.isGameFound = true
                self.performSegue(withIdentifier: "goToQuizz", sender: gameId)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QuizzVC {
            destination.isCompetitiveMode = true
            destination.gameID = sender as? String
        }
    }
    
    func startTimer() {
        // Vérifier que le timer n'a pas déjà été démarré
        guard timer == nil else { return }
        
        // Créer un timer qui se déclenche toutes les 5 secondes
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
            // Appeler la fonction pour mettre à jour les données de jeu
            DispatchQueue.main.async {
                self?.listenForGameStart()
            }
        }
    }
}

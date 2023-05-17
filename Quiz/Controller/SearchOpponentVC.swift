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
            Game.shared.cancelSearch(){ result in
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
        Game.shared.listenForGameStart { success, gameId in
            if success {
                self.isGameFound = true
                // Lancez la partie ici
                // Par exemple, vous pouvez naviguer vers un nouveau ViewController pour afficher le quizz
                self.performSegue(withIdentifier: "goToQuizz", sender: gameId)
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

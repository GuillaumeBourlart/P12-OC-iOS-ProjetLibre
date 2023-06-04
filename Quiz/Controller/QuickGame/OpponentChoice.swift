//
//  OpponentChoice.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 22/04/2023.
//

import Foundation
import UIKit

class OpponentChoice: UIViewController {
    
    @IBOutlet var buttons: [UIButton]!
    
    var difficulty: String?
    var category: Int?
    
    override func viewDidLoad(){
        super.viewDidLoad()
    }
    
    @IBAction func onTap(_ sender: UIButton){
        guard let currentUserId = Game.shared.currentUserId else {
            return
        }
        switch sender.tag {
        case 0: Game.shared.createGame(category: category, difficulty: difficulty, with: nil, competitive: false, players: [currentUserId]) { reuslt in
            switch reuslt {
            case .failure(let error): print(error)
            case .success(let gameID): self.performSegue(withIdentifier: "goToQuizz", sender: gameID)
            }
        }
        case 1:
            Game.shared.createRoom { result in
                switch result {
                case .failure(let error): print(error)
                case .success(let lobbyID): self.performSegue(withIdentifier: "goToPrivateLobby", sender: lobbyID)
                }
            }
        
            
        default:
            print("error")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QuizzVC {
            destination.gameID = sender as? String
            destination.isCompetitive = false
            
        }
        else if let destination = segue.destination as? PrivateLobbyVC {
            destination.lobbyId = sender as? String
            destination.isCreator = true
            destination.category = self.category
            destination.difficulty = self.difficulty
            
        }
    }
    
    @IBAction func unwindToOpponentChoice(segue: UIStoryboardSegue) {
        // Vous pouvez utiliser cette méthode pour effectuer des actions lorsque l'unwind segue est exécuté.
    }
    
    
}

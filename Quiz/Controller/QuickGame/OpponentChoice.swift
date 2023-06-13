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
    var quizId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        for button in self.buttons {
            button.isEnabled = true
        }
    }
    
    @IBAction func onTap(_ sender: UIButton) {
        for button in self.buttons {
            button.isEnabled = false
        }

        // Début de l'animation
        CustomAnimations.buttonPressAnimation(for: sender) {
            guard let currentUserId = Game.shared.currentUserId else {
                return
            }
            switch sender.tag {
            case 0: Game.shared.createQuestionsForGame(quizId: self.quizId, category: self.category, difficulty: self.difficulty, with: nil, competitive: false, players: [currentUserId]) { reuslt in
                switch reuslt {
                case .failure(let error): print(error)
                    for button in self.buttons {
                        button.isEnabled = true
                    }
                case .success(let gameID): self.performSegue(withIdentifier: "goToQuizz", sender: gameID)
                    
                }
            }
            case 1:
                Game.shared.createRoom(quizID: self.quizId) { result in
                    switch result {
                    case .failure(let error): print(error)
                        for button in self.buttons {
                            button.isEnabled = true
                        }
                    case .success(let lobbyID): self.performSegue(withIdentifier: "goToPrivateLobby", sender: lobbyID)
                        
                    }
                }
            default:
                print("error")
                for button in self.buttons {
                    button.isEnabled = true
                }
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QuizzVC {
            destination.gameID = sender as? String
            destination.isCompetitive = false
            
        }
        else if let destination = segue.destination as? PrivateLobbyVC {
            destination.quizId = quizId
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

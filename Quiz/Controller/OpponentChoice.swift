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
    
    
    override func viewDidLoad(){
        
    }
    
    @IBAction func onTap(_ sender: UIButton){
        switch sender.tag {
        case 0: Game.shared.createGame(competitive: false, players: [Game.shared.currentUserId!], creator: Game.shared.currentUserId!) { reuslt in
            switch reuslt {
            case .failure(let error): print(error)
            case .success(let gameID): self.performSegue(withIdentifier: "goToQuizz", sender: gameID)
            }
        }
        case 1: performSegue(withIdentifier: "goToGameLobby", sender: sender)
            
        default:
            print("error")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QuizzVC {
            destination.isCompetitiveMode = false
            destination.gameID = sender as? String
        }
    }
    
    
    
}

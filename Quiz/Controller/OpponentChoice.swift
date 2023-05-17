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
        case 0: performSegue(withIdentifier: "goToQuizz", sender: sender)
        case 1: performSegue(withIdentifier: "goToGameLobby", sender: sender)
            
        default:
            print("error")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QuizzVC {
            destination.isCompetitiveMode = false
        }
    }
    
    
    
}

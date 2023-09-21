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
    
    @IBOutlet weak var soloImage: CustomButton2!
    @IBOutlet weak var multiImage: CustomButton2!
    
    
    var difficulty: String?
    var category: Int?
    var quizId: String?
    
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Method called when view will appear
    override func viewWillAppear(_ animated: Bool) {
        for button in self.buttons {
            button.isEnabled = true
        }
        updateImageViewForCurrentTraitCollection()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                // Mettre à jour l'image lorsque le mode clair/sombre change
                updateImageViewForCurrentTraitCollection()
            }
        }

    func updateImageViewForCurrentTraitCollection() {
        if traitCollection.userInterfaceStyle == .dark {
            // Mode sombre
            soloImage.setImage(UIImage(named: "soloWhite"), for: .normal)
            multiImage.setImage(UIImage(named: "multiplayersWhite"), for: .normal)
        } else {
            // Mode clair
            multiImage.setImage(UIImage(named: "multiplayers"), for: .normal)
            soloImage.setImage(UIImage(named: "solo"), for: .normal)
        }
    }
    
    @IBAction func onTap(_ sender: UIButton) {
        for button in self.buttons {
            button.isEnabled = false
        }
        
        CustomAnimations.buttonPressAnimation(for: sender) {
            
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            
            
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
                for button in self.buttons {
                    button.isEnabled = true
                }
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? GameVC {
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
    }
    
    
}

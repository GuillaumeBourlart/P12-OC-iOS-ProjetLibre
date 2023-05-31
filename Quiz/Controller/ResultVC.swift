//
//  ResultVC.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 11/05/2023.
//

import Foundation
import UIKit


class ResultVC: UIViewController {
    @IBOutlet weak var label : UILabel!
    var gameID: String?
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var goToAppLobby: UIButton!
    var gameData: GameData?
    var questions: [UniversalQuestion]?
    var isResultAfterGame: Bool?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isResultAfterGame != nil {
            goToAppLobby.isHidden = false
        }
        
        if let gameID = gameID {
            Game.shared.getGameData(gameId: gameID) { [weak self] result in
                switch result {
                case .success(let gameData):
                    self?.gameData = gameData
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                case .failure(let error):
                    print("Failed to fetch game data: \(error)")
                }
            }
        }
        
        displayWinner()
        
    }
    
    
    @IBAction func goBackToLobbby(_ sender: Any) {
        if let viewControllers = self.tabBarController?.viewControllers {
            print("Found \(viewControllers.count) view controllers in tab bar")
            for viewController in viewControllers {
                if let navigationController = viewController as? UINavigationController {
                    print("Found a navigation controller with \(navigationController.viewControllers.count) view controllers")
                    navigationController.popToRootViewController(animated: false)
                    print("After pop, it now has \(navigationController.viewControllers.count) view controllers")
                } else {
                    print("Found a view controller that is not a navigation controller: \(viewController)")
                }
            }
        } else {
            print("self does not have a tabBarController")
        }
    }
    
    
    func displayWinner() {
        guard let finalScores = gameData?.final_scores, finalScores.count >= (gameData?.players.count)! else {
            // Si nous n'avons pas encore les scores finaux de deux joueurs, nous demandons à l'utilisateur de rafraîchir plus tard.
            self.label.text = "Veuillez rafraîchir plus tard pour voir le vainqueur. Tout les jouerus n'ont pas encore terminé"
            return
        }
        
        // Ici, je suppose que vous avez les identifiants des utilisateurs dans les clés du dictionnaire finalScores.
        var bestScore = 0
        var winner = [String: Int]()
        for (key, value) in finalScores {
            if value > bestScore {
                bestScore = value
                winner = [:]
                winner[key] = value
            }
            
            
        }
        
        self.label.text = "le joeur \(winner.first!.key) à gagné avec \(winner.first!.value) points"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QuestionResultVC {
            destination.question = sender as? UniversalQuestion
        }
    }
}
extension ResultVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 70.0 // Remplacer par la hauteur désirée
        }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameData?.questions.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuestionCell", for: indexPath) as? CustomCell else { return UITableViewCell() }
        
        let questionsArray = Array(gameData?.questions ?? [:])
        if indexPath.row < questionsArray.count {
            let question = questionsArray[indexPath.row]
            cell.label.text = question.value.question
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Question sélectionnée à la ligne: \(indexPath.row)")
        
        
        tableView.deselectRow(at: indexPath, animated: true) // Désélectionnez la cellule pour une meilleure expérience utilisateur
        
        let selectedQuestion = questions![indexPath.row]
            print("Informations du quiz sélectionné : \(selectedQuestion)")
        performSegue(withIdentifier: "goToQuestionResult", sender: selectedQuestion)
    }
    
    
}








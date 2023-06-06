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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var goToAppLobby: UIButton!
    
    var gameID: String?
    var gameData: GameData?
    var questions: [String: UniversalQuestion]?
    var isResultAfterGame: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isResultAfterGame != nil {
            goToAppLobby.isHidden = false
        }
        
        if let gameID = gameID {
            Game.shared.getGameData(gameId: gameID) { result in
                switch result {
                case .success(let gameData):
                    self.gameData = gameData
                    self.questions = gameData.questions
                    print(gameData.questions)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print("Failed to fetch game data: \(error)")
                }
            }
        } else if let gameData = gameData {
            self.questions = gameData.questions
        }
        
        displayWinner()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isResultAfterGame != nil, isResultAfterGame == true{
            navigationController?.setNavigationBarHidden(true, animated: true)
                tabBarController?.tabBar.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isResultAfterGame != nil, isResultAfterGame == true{
            navigationController?.setNavigationBarHidden(false, animated: true)
                tabBarController?.tabBar.isHidden = false
        }
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
        guard let finalScores = gameData?.final_scores, finalScores.count == gameData?.players.count else {
            self.label.text = "Veuillez rafraîchir plus tard pour voir le vainqueur. Tous les joueurs n'ont pas encore terminé"
            return
        }

        // Find the best score
        var bestScore = 0
        for (_, value) in finalScores {
            if value > bestScore {
                bestScore = value
            }
        }

        // Find all players with the best score
        var winners = [String]()
        for (key, value) in finalScores {
            if value == bestScore {
                winners.append(key)
            }
        }

        // Display the winners
        if winners.count > 1 {
            let winnersList = winners.joined(separator: ", ")
            self.label.text = "Les joueurs \(winnersList) ont gagné avec \(bestScore) points"
        } else {
            self.label.text = "Le joueur \(winners.first) a gagné avec \(bestScore) points"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QuestionResultVC,
           let selectedQuestionDict = sender as? [String: UniversalQuestion] {
            destination.question = selectedQuestionDict
            destination.usersAnswer = gameData?.user_answers
        }
    }
}
extension ResultVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 70.0 // Remplacer par la hauteur désirée
        }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(self.questions?.count)
        return self.questions?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QuestionCell", for: indexPath) as? CustomCell else { return UITableViewCell() }
        
        let questionsArray = Array(self.questions ?? [:])
        if indexPath.row < questionsArray.count {
            let question = questionsArray[indexPath.row]
            cell.label.text = question.value.question
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Question sélectionnée à la ligne: \(indexPath.row)")
        
        tableView.deselectRow(at: indexPath, animated: true) // Désélectionnez la cellule pour une meilleure expérience utilisateur
        
        guard let questionsDict = questions else {
            print("questions is nil")
            return
        }
        
        let questionsArray = Array(questionsDict)
        if indexPath.row < questionsArray.count {
            let selectedQuestionKey = questionsArray[indexPath.row].0
            let selectedQuestionValue = questionsArray[indexPath.row].1
            let selectedQuestionDict = [selectedQuestionKey: selectedQuestionValue]
            print("Informations du quiz sélectionné : \(selectedQuestionDict)")
            performSegue(withIdentifier: "goToQuestionResult", sender: selectedQuestionDict)
        }
    }
    
    
}








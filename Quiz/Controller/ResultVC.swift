//
//  ResultVC.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 11/05/2023.
//

import Foundation
import UIKit
import FirebaseFirestore

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
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isResultAfterGame != nil, isResultAfterGame == true{
            navigationController?.setNavigationBarHidden(true, animated: true)
                tabBarController?.tabBar.isHidden = true
        }
        displayResults()
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
    
    
    func displayResults() {
        guard let gameData = self.gameData else {
            print("No game data available.")
            return
        }
        
        var finalScores = gameData.final_scores ?? [:]
        let UIDS = Array(finalScores.keys)
        FirebaseUser.shared.getUsernames(with: UIDS) { result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let UidsWithusernames):
                var final_scoresWithUsernames = [String: Int]()
                for (key, value) in UidsWithusernames {
                    final_scoresWithUsernames[value] = finalScores[key]
                }
                finalScores = final_scoresWithUsernames
                
                let competitive = gameData.competitive
                
                DispatchQueue.main.async {  // Make sure UI updates are on main thread
                    if competitive {
                        // Competitive game, just show winner and loser
                        let sortedScores = finalScores.sorted { $0.value > $1.value }
                        let winner = sortedScores.first?.key ?? "Unknown"
                        let loser = sortedScores.last?.key ?? "Unknown"
                        
                        self.label.text = "Le gagnant est \(winner), et le perdant est \(loser)."
                    } else {
                        // Non-competitive game, display ranking
                        let sortedScores = finalScores.sorted { $0.value > $1.value }
                        var rankingText = "Classement :\n"
                        for (index, element) in sortedScores.enumerated() {
                            rankingText += "\(index + 1). \(element.key) avec \(element.value) points\n"
                        }
                        
                        self.label.text = rankingText
                    }
                }
            }
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








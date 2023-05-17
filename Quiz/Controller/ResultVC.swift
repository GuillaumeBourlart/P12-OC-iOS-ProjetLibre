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
    
    var gameData: GameData?
    var questions: [UniversalQuestion]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    }
}
extension ResultVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameData?.questions.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuestionCell", for: indexPath)
        
        let questionsArray = Array(gameData?.questions ?? [:])
        if indexPath.row < questionsArray.count {
            let question = questionsArray[indexPath.row]
            cell.textLabel?.text = questionsArray[indexPath.row].value.question
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Question sélectionnée à la ligne: \(indexPath.row)")
    }
}








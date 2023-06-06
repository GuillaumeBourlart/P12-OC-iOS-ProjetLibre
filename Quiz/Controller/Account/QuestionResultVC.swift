//
//  QuestionResultVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 30/05/2023.
//

import Foundation
import UIKit
class QuestionResultVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var correctAnswerLabel: UILabel!
    
    var usersAnswer: [String: [String: UserAnswer]]?
    var question: [String: UniversalQuestion]?
    
    override func viewDidLoad() {
            super.viewDidLoad()

            guard let questionData = question?.values.first else { return }
            questionLabel.text = questionData.question
            correctAnswerLabel.text = "Bonne réponse : \(questionData.correct_answer)"
        }
    
}

extension QuestionResultVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return usersAnswer?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let usersAnswer = usersAnswer, !usersAnswer.keys.isEmpty {
            let keys = Array(usersAnswer.keys)
            return keys[section]
        } else {
            return nil // or return "" if you want to return an empty string
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 // Chaque utilisateur a une seule réponse pour cette question spécifique
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        guard let usersAnswer = usersAnswer else { return cell }

        let userID = Array(usersAnswer.keys)[indexPath.section]
        guard let userAnswers = usersAnswer[userID],
              let questionKey = question?.keys.first,
              let userAnswer = userAnswers[questionKey] else { return cell }
        
        cell.selectionStyle = .none // Désactive la sélection visuelle
        cell.textLabel?.text = "Réponse : \(userAnswer.selected_answer)"
        cell.textLabel?.textColor = userAnswer.selected_answer == question?.values.first?.correct_answer ? .green : .red
        cell.detailTextLabel?.text = "Points gagnés : \(userAnswer.points)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let usersAnswer = usersAnswer else { return UIView() }
        let headerView = UIView()
        headerView.backgroundColor = tableView.backgroundColor // À définir selon vos préférences

        let headerLabel = UILabel(frame: CGRect(x: 15, y: 0, width:
            tableView.bounds.size.width, height: tableView.sectionHeaderHeight))
        headerLabel.font = UIFont(name: "Helvetica", size: 20) // À définir selon vos préférences
        headerLabel.textColor = .white
        headerLabel.text = Array(usersAnswer.keys)[section]
        headerLabel.sizeToFit()

        headerView.addSubview(headerLabel)

        return headerView
    }
}

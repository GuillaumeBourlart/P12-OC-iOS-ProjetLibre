//
//  QuestionResultVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 30/05/2023.
//

import Foundation
import UIKit
// Class that show result of a specific question
class QuestionResultVC: UIViewController {
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var correctAnswerLabel: UILabel!
    // Properties
    var usersAnswer: [String: [String: UserAnswer]]?
    var question: [String: UniversalQuestion]?
    var usernamesForUIDs = [String: String]()
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let questionData = question?.values.first else { return }
        questionLabel.text = questionData.question
        let localizedCorrectAnswer = NSLocalizedString("Correct answer: %@", comment: "The correct answer to the question")
        correctAnswerLabel.text = String(format: localizedCorrectAnswer, questionData.correct_answer)
        
        // Get usernames for UIDs
        if let userIDs = usersAnswer?.keys {
            FirebaseUser.shared.getUsernames(with: Array(userIDs)) { [weak self] result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let usernamesDict):
                    self?.usernamesForUIDs = usernamesDict
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                }
            }
        }
    }
    
}

extension QuestionResultVC: UITableViewDataSource, UITableViewDelegate {
    
    // Define the number of sections in the table view based on the number of users' answers
    func numberOfSections(in tableView: UITableView) -> Int {
        return usersAnswer?.count ?? 0
    }
    
    // Provide a title for each section's header based on the user's name or UID
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let usersAnswer = usersAnswer, !usersAnswer.keys.isEmpty {
            let keys = Array(usersAnswer.keys)
            let userID = keys[section]
            
            // Use the username if available, otherwise use the UID
            return usernamesForUIDs[userID] ?? userID
        } else {
            return nil // Return nil if no user answers are available (or return "" for an empty string)
        }
    }
    
    // Define the number of rows in each section (always 1 in this case)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Configure and return a cell for a specific row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        guard let usersAnswer = usersAnswer else { return cell }
        let userID = Array(usersAnswer.keys)[indexPath.section]
        
        guard let userAnswers = usersAnswer[userID],
              let questionKey = question?.keys.first,
              let userAnswer = userAnswers[questionKey] else { return cell }
        
        cell.selectionStyle = .none
        
        // Localize the answer and points information
        let localizedAnswer = NSLocalizedString("Answer: %@", comment: "User's selected answer")
        cell.textLabel?.text = String(format: localizedAnswer, userAnswer.selected_answer)
        
        // Set the text color to green if the answer is correct, otherwise, set it to red
        cell.textLabel?.textColor = userAnswer.selected_answer == question?.values.first?.correct_answer ? .green : .red
        
        // Localize the points information
        let localizedPoints = NSLocalizedString("Points: %d", comment: "User's points for the answer")
        cell.detailTextLabel?.text = String(format: localizedPoints, userAnswer.points)
        
        return cell
    }
    
    // Provide a custom view for each section's header
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let usersAnswer = usersAnswer else { return UIView() }
        let headerView = UIView()
        headerView.backgroundColor = tableView.backgroundColor
        
        // Create a label for the header
        let headerLabel = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.bounds.size.width, height: tableView.sectionHeaderHeight))
        headerLabel.font = UIFont(name: "Helvetica", size: 20)
        headerLabel.textColor = UIColor(named: "text")
        
        let userID = Array(usersAnswer.keys)[section]
        
        // Use the username if available, otherwise use the UID
        headerLabel.text = usernamesForUIDs[userID] ?? userID
        
        headerLabel.sizeToFit()
        headerView.addSubview(headerLabel)
        
        return headerView
    }
}

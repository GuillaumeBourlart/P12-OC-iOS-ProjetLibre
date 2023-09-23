//
//  Modification.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 03/05/2023.
//
import FirebaseFirestore
import Foundation
import UIKit

// class to modify a quiz (name, difficulty, theme and questions)
class ModifyQuizVC: UIViewController{
    // Outlets
    @IBOutlet weak var modifyButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var themeLabel: UILabel!
    @IBOutlet weak var themeField: UITextField!
    @IBOutlet weak var difficultyLabel: UILabel!
    @IBOutlet weak var difficultyField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var launchQuizButton: UIButton!
    @IBOutlet weak var addQuestionButton: UIButton!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    // Properties
    var quizID: String?
    var quiz: Quiz? { return FirebaseUser.shared.userQuizzes?.first(where: { $0.id == quizID }) }
    var usernames = [String: String]()
    var isModifying = false
    
    // Method called when view is loaded
    override func viewDidLoad() {
        tapGestureRecognizer.cancelsTouchesInView = false
        super.viewDidLoad()
        if quiz != nil {
            nameField.text = quiz?.name
            themeField.text = quiz?.category_id
            difficultyField.text = quiz?.difficulty
        }
    }
    
    // Method called when view will appear
    override func viewWillAppear(_ animated: Bool) {
        launchQuizButton.isEnabled = true
        addQuestionButton.isEnabled = true
        modifyButton.isEnabled = true
        tableView.reloadData()
    }
    
    // Activate or deactivate name, theme and difficulty modification
    @IBAction func modifyButtonWasTapped(_ sender: UIButton) {
        self.addQuestionButton.isEnabled = false
        self.launchQuizButton.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: sender) {
            
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            
            if self.isModifying {
                self.isModifying = false
                self.nameField.layer.borderColor = UIColor.clear.cgColor
                self.nameField.isUserInteractionEnabled = false
                self.themeField.layer.borderColor = UIColor.clear.cgColor
                self.themeField.isUserInteractionEnabled = false
                self.difficultyField.layer.borderColor = UIColor.clear.cgColor
                self.difficultyField.isUserInteractionEnabled = false
                self.modifyButton.setImage(UIImage(systemName: "pencil"), for: .normal)
                self.modifyButton.backgroundColor = UIColor.red
                
                self.nameField.layer.borderWidth = 0
                self.themeField.layer.borderWidth = 0
                self.difficultyField.layer.borderWidth = 0
                
                self.saveModifications()
            }else {
                self.isModifying = true
                self.nameField.layer.borderColor = UIColor.green.cgColor
                self.nameField.isUserInteractionEnabled = true
                self.themeField.layer.borderColor = UIColor.green.cgColor
                self.themeField.isUserInteractionEnabled = true
                self.difficultyField.layer.borderColor = UIColor.green.cgColor
                self.difficultyField.isUserInteractionEnabled = true
                
                self.nameField.layer.borderWidth = 1
                self.themeField.layer.borderWidth = 1
                self.difficultyField.layer.borderWidth = 1
                
                self.modifyButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
                self.modifyButton.backgroundColor = UIColor.green
            }
            
            
        }
    }
    
    // Save name, theme and difficulty modification
    func saveModifications(){
        if let quiz = quiz {
            guard let name = nameField.text, name != "", let theme = themeField.text,theme != "", let difficulty = difficultyField.text, difficulty != "" else {return}
            
            FirebaseUser.shared.updateQuiz(quizID: quiz.id, newName: name, newCategoryID: theme, newDifficulty: difficulty) { result in
                switch result {
                case .success():
                    self.tableView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                }
                self.addQuestionButton.isEnabled = true
                self.launchQuizButton.isEnabled = true
            }
        }
        
    }
    
    // navigate to addQuestionVC so user can create a question
    @IBAction func addButtonTapped(_ sender: UIButton) {
        self.addQuestionButton.isEnabled = false
        self.launchQuizButton.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: sender) {
            
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            
            self.addQuestionButton.isEnabled = false
            self.modifyButton.isEnabled = false
            self.launchQuizButton.isEnabled = false
            if self.quiz != nil {
                self.performSegue(withIdentifier: "goToAddQuestion", sender: self)
            }  else {
                self.addQuestionButton.isEnabled = true
                self.launchQuizButton.isEnabled = true
            }
        }
    }
    
    // Called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? AddQuestionVC {
            if let questionData = sender as? (id: String, question: UniversalQuestion) {
                destination.existingQuestionId = questionData.id
                destination.existingQuestion = questionData.question
                destination.quiz = self.quiz
            } else {
                destination.quiz = self.quiz
            }
        }
        
        if let destination = segue.destination as? OpponentChoice{
            destination.quizId = quizID
        }
    }
    
    // handle keyboard dismissing
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        nameField.resignFirstResponder()
        themeField.resignFirstResponder()
        difficultyField.resignFirstResponder()
    }
    
    // Launch the quiz
    @IBAction func lauchQuizButtonPressed(_ sender: UIButton) {
        self.addQuestionButton.isEnabled = false
        self.launchQuizButton.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: sender) {
            
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            
            self.modifyButton.isEnabled = false
            if let quizID = self.quizID {
                Game.shared.createRoom(quizID: quizID) { result in
                    switch result {
                    case .failure(let error): print(error)
                        self.addQuestionButton.isEnabled = true
                        self.launchQuizButton.isEnabled = true
                    case .success(let lobbyId): self.performSegue(withIdentifier: "goToOpponentChoice", sender: lobbyId)
                    }
                }
            }
        }
    }
}

extension ModifyQuizVC: UITableViewDelegate, UITableViewDataSource {
    
    // Set the height for each row in the table view
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0 // Replace with the desired height
    }
    
    // Define the number of rows in the table view based on the number of questions in the quiz
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let quiz = quiz {
            return quiz.questions.count
        } else {
            return 0
        }
    }
    
    // Configure and return a cell for a specific row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
        
        if let quiz = quiz {
            let question = Array(quiz.questions.values)[indexPath.row]
            cell.label.text = question.question // Change question.text to question.question
        }
        
        // Create a disclosure indicator for the cell
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    // Handle deletion of a row in the table view
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let quiz = quiz {
                if tableView.cellForRow(at: indexPath) is CustomCell {
                    
                    let questionIdToDelete = Array(quiz.questions.keys)[indexPath.row]
                    
                    // Delete the question from the database
                    FirebaseUser.shared.deleteQuestionFromQuiz(quiz: quiz, questionId: questionIdToDelete) { result in
                        switch result {
                        case .success:
                            // Reload the table view after successfully removing the question
                            tableView.reloadData()
                        case .failure(let error):
                            print("Error removing question: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    // Handle row selection in the table view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Deselect the cell after the click
        
        if let quiz = quiz {
            let selectedQuestionId = Array(quiz.questions.keys)[indexPath.row]
            
            guard let question = quiz.questions[selectedQuestionId] else {
                return
            }
            
            // Prepare question data and perform a segue to add/edit the question
            let questionData = (id: selectedQuestionId, question: question)
            performSegue(withIdentifier: "goToAddQuestion", sender: questionData)
        }
    }
}

extension ModifyQuizVC: UITextFieldDelegate {
    
    // Handle the return key on text fields to resign first responder status
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameField.resignFirstResponder()
        themeField.resignFirstResponder()
        difficultyField.resignFirstResponder()
        return true
    }
}



//
//  Modification.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 03/05/2023.
//
import FirebaseFirestore
import Foundation
import UIKit

class ModifyQuizVC: UIViewController{
    
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
    
    var quizID: String?
    var quiz: Quiz? {
        return FirebaseUser.shared.userQuizzes?.first(where: { $0.id == quizID })
    }
    var usernames = [String: String]()
    var isModifying = false
    
    override func viewDidLoad() {
        tapGestureRecognizer.cancelsTouchesInView = false
        super.viewDidLoad()
        if quiz != nil {
            nameField.text = quiz?.name
            themeField.text = quiz?.category_id
            difficultyField.text = quiz?.difficulty
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        launchQuizButton.isEnabled = true
        addQuestionButton.isEnabled = true
        modifyButton.isEnabled = true
    }
    
    
    
    @IBAction func modifyButtonWasTapped(_ sender: UIButton) {
        self.addQuestionButton.isEnabled = false
        self.launchQuizButton.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: sender) {
            
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
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        self.addQuestionButton.isEnabled = false
        self.launchQuizButton.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: sender) {
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
    
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        nameField.resignFirstResponder()
        themeField.resignFirstResponder()
        difficultyField.resignFirstResponder()
    }
    
    
    @IBAction func lauchQuizButtonPressed(_ sender: UIButton) {
        self.addQuestionButton.isEnabled = false
        self.launchQuizButton.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: sender) {
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0 // Remplacer par la hauteur désirée
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let quiz = quiz {
            return quiz.questions.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
        
        if let quiz = quiz {
            let question = Array(quiz.questions.values)[indexPath.row]
            cell.label.text = question.question // Change question.text to question.question
        }
        
        
        let whiteDisclosureIndicator = UIImageView(image: UIImage(systemName: "chevron.right"))
        whiteDisclosureIndicator.tintColor = .white // Remplacez "customDisclosureIndicator" par le nom de votre image.
        whiteDisclosureIndicator.backgroundColor = UIColor.clear
        whiteDisclosureIndicator.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
        cell.accessoryView = whiteDisclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let quiz = quiz {
                if tableView.cellForRow(at: indexPath) is CustomCell {
                    
                    let questionIdToDelete = Array(quiz.questions.keys)[indexPath.row]
                    
                    // Supprimer la question de la base de données
                    FirebaseUser.shared.deleteQuestionFromQuiz(quiz: quiz, questionId: questionIdToDelete) { result in
                        switch result {
                        case .success():
                            // Supprimer la question de la table view
                            tableView.reloadData()
                        case .failure(let error):
                            print("Error removing question : \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Désélectionner la cellule après le clic
        if let quiz = quiz {
            let selectedQuestionId = Array(quiz.questions.keys)[indexPath.row]
            guard let question = quiz.questions[selectedQuestionId] else {
                return
            }
            let questionData = (id: selectedQuestionId, question: question)
            performSegue(withIdentifier: "goToAddQuestion", sender: questionData)
        }
    }
}
extension ModifyQuizVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameField.resignFirstResponder()
        themeField.resignFirstResponder()
        difficultyField.resignFirstResponder()
        return true
    }
}


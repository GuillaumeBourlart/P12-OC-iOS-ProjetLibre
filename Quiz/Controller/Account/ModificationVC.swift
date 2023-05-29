//
//  Modification.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 03/05/2023.
//
import FirebaseFirestore
import Foundation
import UIKit

class ModificationVC: UIViewController{
    
    @IBOutlet weak var modifyButton: UIButton!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var themeLabel: UILabel!
    
    @IBOutlet weak var themeField: UITextField!
    
    @IBOutlet weak var difficultyLabel: UILabel!
    
    @IBOutlet weak var difficultyField: UITextField!
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var quizID: String?
    var groupID: String?
    
    var quiz: Quiz? {
        return FirebaseUser.shared.userQuizzes?.first(where: { $0.id == quizID })
    }
    
    var group: FriendGroup? {
        return FirebaseUser.shared.friendGroups?.first(where: { $0.id == groupID })
    }
    
    var isModifying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if quiz != nil {
            nameField.text = quiz?.name
            themeField.text = quiz?.category_id
            difficultyField.text = quiz?.difficulty
        }
        else if group != nil {
            nameField.text = group?.name
            themeField.isHidden = true
            themeLabel.isHidden = true
            difficultyField.isHidden = true
            difficultyLabel.isHidden = true
        }
        
    }
    
    
    
    @IBAction func modifyButtonWasTapped(_ sender: Any) {
        if quiz != nil {
            if isModifying {
                isModifying = false
                nameField.layer.borderColor = UIColor.clear.cgColor
                nameField.isUserInteractionEnabled = false
                themeField.layer.borderColor = UIColor.clear.cgColor
                themeField.isUserInteractionEnabled = false
                difficultyField.layer.borderColor = UIColor.clear.cgColor
                difficultyField.isUserInteractionEnabled = false
                modifyButton.setImage(UIImage(systemName: "pencil"), for: .normal)
                modifyButton.backgroundColor = UIColor.red
                
                nameField.layer.borderWidth = 0
                themeField.layer.borderWidth = 0
                difficultyField.layer.borderWidth = 0
                
                saveModifications()
            }else {
                isModifying = true
                nameField.layer.borderColor = UIColor.green.cgColor
                nameField.isUserInteractionEnabled = true
                themeField.layer.borderColor = UIColor.green.cgColor
                themeField.isUserInteractionEnabled = true
                difficultyField.layer.borderColor = UIColor.green.cgColor
                difficultyField.isUserInteractionEnabled = true
                
                nameField.layer.borderWidth = 1
                themeField.layer.borderWidth = 1
                difficultyField.layer.borderWidth = 1
                
                modifyButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
                modifyButton.backgroundColor = UIColor.green
            }
            
        }
        
        
        else if group != nil {
            if isModifying {
                isModifying = false
                nameField.layer.borderColor = UIColor.clear.cgColor
                
                nameField.isUserInteractionEnabled = false
                themeField.isUserInteractionEnabled = false
                difficultyField.isUserInteractionEnabled = false
                
                nameField.layer.borderWidth = 0
                themeField.layer.borderWidth = 0
                difficultyField.layer.borderWidth = 0
                
                modifyButton.backgroundColor = UIColor.red
                modifyButton.setImage(UIImage(systemName: "pencil"), for: .normal)
                
                saveModifications()
            }else {
                isModifying = true
                nameField.layer.borderColor = UIColor.green.cgColor
                nameField.isUserInteractionEnabled = true
                themeField.isUserInteractionEnabled = true
                difficultyField.isUserInteractionEnabled = true
                
                nameField.layer.borderWidth = 1
                themeField.layer.borderWidth = 1
                difficultyField.layer.borderWidth = 1
                
                modifyButton.backgroundColor = UIColor.green
                modifyButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
            }
        }
    }
    
    func saveModifications(){
        if let quiz = quiz {
            guard let name = nameField.text, let theme = themeField.text, let difficulty = difficultyField.text else {return}
            
            FirebaseUser.shared.updateQuiz(quizID: quiz.id, newName: name, newCategoryID: theme, newDifficulty: difficulty) { result in
                switch result {
                case .success():
                    print("Quiz modifié avec succès.")
                    self.tableView.reloadData()
                    
                case .failure(let error):
                    print("Erreur lors de la modification des infos du quiz : \(error.localizedDescription)")
                }
            }
            
        }
        
        
        else if let group = group {
            guard let name = nameField.text else {return}
            
            FirebaseUser.shared.updateGroupName(groupID: group.id, newName: name) { result in
                switch result {
                case .success():
                    print("Groupe modifié avec succès.")
                    self.tableView.reloadData()
                    
                case .failure(let error):
                    print("Erreur lors de la modification du nom du groupe d'amis : \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    
    
    @IBAction func addButtonTapped(_ sender: Any) {
        if quiz != nil {
            showAddQuestionAlert()
        } else if group != nil {
            showAddFriendAlert()
        }
    }
    
    func showAddQuestionAlert(for existingQuestion: UniversalQuestion? = nil) {
        let alertController = UIAlertController(title: "Ajouter une question", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Question"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Bonne réponse"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Mauvaise réponse 1"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Mauvaise réponse 2"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Mauvaise réponse 3"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Explication"
        }
        
        if let question = existingQuestion {
            alertController.textFields?[0].text = question.question
            alertController.textFields?[1].text = question.correct_answer
            alertController.textFields?[2].text = question.incorrect_answers[0]
            alertController.textFields?[3].text = question.incorrect_answers[1]
            alertController.textFields?[4].text = question.incorrect_answers[2]
            alertController.textFields?[5].text = question.explanation
        }
        
        let addAction = UIAlertAction(title: "Ajouter", style: .default) { _ in
            guard let question = alertController.textFields?[0].text,
                  let correctAnswer = alertController.textFields?[1].text,
                  let incorrectAnswer1 = alertController.textFields?[2].text,
                  let incorrectAnswer2 = alertController.textFields?[3].text,
                  let incorrectAnswer3 = alertController.textFields?[4].text,
                  let explanation = alertController.textFields?[5].text
            else {
                return
            }
            
            if let existingQuestion = existingQuestion {
                FirebaseUser.shared.updateQuestionInQuiz(quiz: self.quiz!, oldQuestion: existingQuestion, newQuestionText: question, correctAnswer: correctAnswer, incorrectAnswers: [incorrectAnswer1, incorrectAnswer2, incorrectAnswer3], explanation: explanation) { result in
                    switch result {
                    case .success():
                        self.tableView.reloadData()
                    case .failure(let error):
                        print("Erreur lors de la mise à jour de la question : \(error)")
                    }
                }
            } else {
                FirebaseUser.shared.addQuestionToQuiz(quiz: self.quiz!, question: question, correctAnswer: correctAnswer, wrongAnswers: [incorrectAnswer1, incorrectAnswer2, incorrectAnswer3], explanation: explanation) { result in
                    switch result {
                    case .success():
                        self.tableView.reloadData()
                    case .failure(let error):
                        print("Erreur lors de l'ajout de la question : \(error)")
                    }
                }
            }
        }
        alertController.addAction(addAction)
        
        let cancelAction = UIAlertAction(title: "Annuler", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func showAddFriendAlert() {
        let selectFriendsTableViewController = SelectFriendsTableViewController()
        
        let friends = FirebaseUser.shared.fetchFriends()
        
        selectFriendsTableViewController.friends = friends
        
        let alertController = UIAlertController(title: "Ajouter des amis au groupe", message: "\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        
        alertController.setValue(selectFriendsTableViewController, forKey: "contentViewController")
        
        let addAction = UIAlertAction(title: "Ajouter", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            let selectedFriends = selectFriendsTableViewController.selectedFriends
            
            FirebaseUser.shared.addNewMembersToGroup(group: self.group!, newMembers: selectedFriends) { result in
                switch result {
                case .success():
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error adding new members to group: \(error.localizedDescription)")
                }
            }
        }
        
        alertController.addAction(addAction)
        
        let cancelAction = UIAlertAction(title: "Annuler", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
}

extension ModificationVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let quiz = quiz {
            return quiz.questions.count
        }
        else if let group = group {
            return group.members.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
        
        if let quiz = quiz {
            let question = quiz.questions[indexPath.row]
            cell.label.text = question.question // Change question.text to question.question
        }
        else if let group = group {
            let memberId = group.members[indexPath.row] // Get memberId from group.members keys
            cell.label.text = memberId
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print(1)
            if let quiz = quiz {
                print(2)
                print("IndexPath: \(indexPath)")
                if tableView.cellForRow(at: indexPath) is CustomCell {
                    print(3)
                    var questionToDelete: UniversalQuestion?

                    // Trouver la question correspondant à l'index
                    if indexPath.row < quiz.questions.count {
                        questionToDelete = quiz.questions[indexPath.row]
                    }

                    guard let question = questionToDelete else {
                        return
                    }

                    let questionText = question.question // Utilisez le texte de la question comme identifiant

                    // Supprimer la question de la base de données
                    FirebaseUser.shared.deleteQuestionFromQuiz(quiz: quiz, questionText: questionText) { result in
                        switch result {
                        case .success():
                            // Supprimer la question de la table view
                            tableView.reloadData()
                        case .failure(let error):
                            print("Erreur lors de la suppression de la question : \(error.localizedDescription)")
                        }
                    }
                }
            } else if let group = group {
                // Récupérer l'ID du membre à supprimer
                let memberId = group.members[indexPath.row]
                // Supprimer le membre du groupe
                FirebaseUser.shared.removeMemberFromGroup(group: group, memberId: memberId) { result in
                    switch result {
                    case .success():
                        // Mettre à jour la table view
                        tableView.reloadData()
                    case .failure(let error):
                        print("Erreur lors de la suppression du membre : \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Désélectionner la cellule après le clic
        if let quiz = quiz {
            let selectedQuestion = quiz.questions[indexPath.row]
            showAddQuestionAlert(for: selectedQuestion)
        }
    }
    
    
}

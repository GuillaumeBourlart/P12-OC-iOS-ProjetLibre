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
    @IBOutlet weak var launchQuizButton: UIButton!
    @IBOutlet weak var addQuestionButton: UIButton!
    
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    var quizID: String?
    var groupID: String?
    var quiz: Quiz? {
        return FirebaseUser.shared.userQuizzes?.first(where: { $0.id == quizID })
    }
    var group: FriendGroup? {
        return FirebaseUser.shared.friendGroups?.first(where: { $0.id == groupID })
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
        else if group != nil {
            nameField.text = group?.name
            themeField.isHidden = true
            themeLabel.isHidden = true
            difficultyField.isHidden = true
            difficultyLabel.isHidden = true
            launchQuizButton.isHidden = true
        }
    }
        
        override func viewWillAppear(_ animated: Bool) {
            launchQuizButton.isEnabled = true
            addQuestionButton.isEnabled = true
            modifyButton.isEnabled = true
            getUsernames()
        }
    
    func getUsernames(){
        guard let group = group, group.members != [] else { self.usernames = [:]; self.tableView.reloadData(); return}
        FirebaseUser.shared.fetchGroupMembers(group: group) { result in
            switch result {
            case .failure(let error): print(error)
            case .success(let members): self.usernames = members
                self.tableView.reloadData()
            }
        }
    }
        
        @IBAction func modifyButtonWasTapped(_ sender: UIButton) {
            CustomAnimations.buttonPressAnimation(for: sender) {
                self.addQuestionButton.isEnabled = false
                self.launchQuizButton.isEnabled = false
                if self.quiz != nil {
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
                    
                } else if self.group != nil {
                    if self.isModifying {
                        self.isModifying = false
                        self.nameField.layer.borderColor = UIColor.clear.cgColor
                        
                        self.nameField.isUserInteractionEnabled = false
                        self.themeField.isUserInteractionEnabled = false
                        self.difficultyField.isUserInteractionEnabled = false
                        
                        self.nameField.layer.borderWidth = 0
                        self.themeField.layer.borderWidth = 0
                        self.difficultyField.layer.borderWidth = 0
                        
                        self.modifyButton.backgroundColor = UIColor.red
                        self.modifyButton.setImage(UIImage(systemName: "pencil"), for: .normal)
                        
                        self.saveModifications()
                    }else {
                        self.isModifying = true
                        self.nameField.layer.borderColor = UIColor.green.cgColor
                        self.nameField.isUserInteractionEnabled = true
                        self.themeField.isUserInteractionEnabled = true
                        self.difficultyField.isUserInteractionEnabled = true
                        
                        self.nameField.layer.borderWidth = 1
                        self.themeField.layer.borderWidth = 1
                        self.difficultyField.layer.borderWidth = 1
                        
                        self.modifyButton.backgroundColor = UIColor.green
                        self.modifyButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
                    }
                }
            }
        }
        
        func saveModifications(){
            if let quiz = quiz {
                guard let name = nameField.text, name != "", let theme = themeField.text,theme != "", let difficulty = difficultyField.text, difficulty != "" else {return}
                
                FirebaseUser.shared.updateQuiz(quizID: quiz.id, newName: name, newCategoryID: theme, newDifficulty: difficulty) { result in
                    switch result {
                    case .success():
                        print("Quiz modifié avec succès.")
                        self.tableView.reloadData()
                    case .failure(let error):
                        print("Erreur lors de la modification des infos du quiz : \(error.localizedDescription)")
                    }
                    self.addQuestionButton.isEnabled = true
                    self.launchQuizButton.isEnabled = true
                }
            } else if let group = group {
                guard let name = nameField.text, name != "" else {return}
                
                FirebaseUser.shared.updateGroupName(groupID: group.id, newName: name) { result in
                    switch result {
                    case .success():
                        print("Groupe modifié avec succès.")
                        self.tableView.reloadData()
                    case .failure(let error):
                        print("Erreur lors de la modification du nom du groupe d'amis : \(error.localizedDescription)")
                    }
                    self.addQuestionButton.isEnabled = true
                    self.launchQuizButton.isEnabled = true
                }
            }
            
        }
        
        @IBAction func addButtonTapped(_ sender: UIButton) {
            CustomAnimations.buttonPressAnimation(for: sender) {
                self.addQuestionButton.isEnabled = false
                self.modifyButton.isEnabled = false
                self.launchQuizButton.isEnabled = false
                if self.quiz != nil {
                    self.performSegue(withIdentifier: "goToAddQuestion", sender: self)
                } else if self.group != nil {
                    self.performSegue(withIdentifier: "goToAddMember", sender: self)
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
            
            if let destination = segue.destination as? AddMemberVC {
                destination.group = self.group
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
            CustomAnimations.buttonPressAnimation(for: sender) {
                self.addQuestionButton.isEnabled = false
                self.launchQuizButton.isEnabled = false
                self.modifyButton.isEnabled = false
                if let quizID = self.quizID {
                    Game.shared.createRoom(quizID: quizID) { result in
                        switch result {
                        case .failure(let error): print(error)
                            self.launchQuizButton.isEnabled = true
                        case .success(let lobbyId): self.performSegue(withIdentifier: "goToOpponentChoice", sender: lobbyId)
                        }
                    }
                }
            }
        }
    }
    
    extension ModificationVC: UITableViewDelegate, UITableViewDataSource {
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 70.0 // Remplacer par la hauteur désirée
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if let quiz = quiz {
                return quiz.questions.count
            }
            else if let group = group {
                return usernames.count
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
            else if let group = group {
                let userId = Array(usernames.keys)[indexPath.row] // Récupérer l'id d'utilisateur à partir des clés du dictionnaire usernames
                let userName = usernames[userId] // Récupérer le nom d'utilisateur correspondant
                cell.label.text = userName
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
                        let questionIdToDelete = Array(quiz.questions.keys)[indexPath.row]
                        
                        // Supprimer la question de la base de données
                        FirebaseUser.shared.deleteQuestionFromQuiz(quiz: quiz, questionId: questionIdToDelete) { result in
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
                    let memberIdToRemove = Array(usernames.keys)[indexPath.row]
                    FirebaseUser.shared.removeMemberFromGroup(group: group, memberId: memberIdToRemove) { result in
                        switch result {
                        case .success():
                            self.getUsernames()
                        case .failure(let error):
                            print("Error deleting member: \(error.localizedDescription)")
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
    extension ModificationVC: UITextFieldDelegate {
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            nameField.resignFirstResponder()
            themeField.resignFirstResponder()
            difficultyField.resignFirstResponder()
            return true
        }
    }


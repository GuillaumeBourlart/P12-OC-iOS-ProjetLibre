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
    
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
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
            
        } else if group != nil {
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
            guard let name = nameField.text, name != "", let theme = themeField.text,theme != "", let difficulty = difficultyField.text, difficulty != "" else {return}
            
            FirebaseUser.shared.updateQuiz(quizID: quiz.id, newName: name, newCategoryID: theme, newDifficulty: difficulty) { result in
                switch result {
                case .success():
                    print("Quiz modifié avec succès.")
                    self.tableView.reloadData()
                    
                case .failure(let error):
                    print("Erreur lors de la modification des infos du quiz : \(error.localizedDescription)")
                }
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
            }
        }
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        if quiz != nil {
            performSegue(withIdentifier: "goToAddQuestion", sender: self)
        } else if group != nil {
            performSegue(withIdentifier: "goToAddMember", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? AddQuestionVC,
            let questionData = sender as? (id: String, question: UniversalQuestion) {
            destination.existingQuestionId = questionData.id
            destination.existingQuestion = questionData.question
            destination.quiz = self.quiz
        }
        
        if let destination = segue.destination as? AddMemberVC {
            destination.group = self.group
        }
        if let destination = segue.destination as? OpponentChoice{
            destination.quizId = quizID
        }
    }
    
    
    
   
    
    
    
    @IBAction func lauchQuizButtonPressed(_ sender: Any) {
        Game.shared.createRoom(quizID: quizID!) { result in
            switch result {
            case .failure(let error): print(error)
            case .success(let lobbyId): self.performSegue(withIdentifier: "goToOpponentChoice", sender: lobbyId)
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
            return group.members.count
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
            let memberUsername = group.members[indexPath.row] // Get memberId from group.members keys
            cell.label.text = memberUsername
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
                let memberIdToRemove = group.members[indexPath.row]
                FirebaseUser.shared.removeMemberFromGroup(group: group, memberId: memberIdToRemove) { result in
                    switch result {
                    case .success():
                        tableView.reloadData()
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

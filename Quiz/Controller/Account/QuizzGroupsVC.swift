//
//  File.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 24/04/2023.
//

import Foundation
import UIKit

class QuizzGroupsVC: UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    
    var isQuizList: Bool?
    var quizzes: [Quiz] { return FirebaseUser.shared.userQuizzes ?? [] }
    var groups: [FriendGroup] { return FirebaseUser.shared.friendGroups ?? [] }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.3)
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isQuizList != nil, isQuizList == true  {
            FirebaseUser.shared.getUserQuizzes { result in
                switch result {
                case .success():
                    self.navigationItem.title = "Quizz"
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error getting quizzes : \(error.localizedDescription)")
                    // Afficher une alerte à l'utilisateur ou gérer l'erreur de manière appropriée
                }
            }
        } else {
            FirebaseUser.shared.getUserGroups { result in
                switch result {
                case .success():
                    self.navigationItem.title = "Groupes"
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error getting groups: \(error.localizedDescription)")
                    // Afficher une alerte à l'utilisateur ou gérer l'erreur de manière appropriée
                }
            }
        }
    }
    
    @IBAction func plusButtonTapped(_ sender: Any) {
        if isQuizList != nil, isQuizList == true  {
            displayAddQuizAlert()
        } else{
            displayAddGroupAlert()
        }
    }
    
    func displayAddQuizAlert() {
        let alert = UIAlertController(title: "Add a quiz", message: "Enter name, category and difficulty", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Name"
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Category"
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Difficulty"
            textField.autocorrectionType = .no
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { (_) in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let category = alert.textFields?[1].text, !category.isEmpty,
                  let difficulty = alert.textFields?[2].text, !difficulty.isEmpty else { return }
            
            FirebaseUser.shared.addQuiz(name: name, category_id: category, difficulty: difficulty) { result in
                switch result {
                case .success():
                    print("Quiz successfully added ")
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error adding quiz : \(error.localizedDescription)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func displayAddGroupAlert() {
        let alert = UIAlertController(title: "Add a group", message: "Enter group name", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Name"
            textField.autocorrectionType = .no 
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { (_) in
            guard let name = alert.textFields?[0].text, !name.isEmpty else { return }
            
            FirebaseUser.shared.addGroup(name: name) { result in
                switch result {
                case .success():
                    print("Group successfully added")
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error adding group : \(error.localizedDescription)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ModificationVC {
            if let quiz = sender as? Quiz{
                destination.quizID = quiz.id
            }
            if let group = sender as? FriendGroup {
                destination.groupID = group.id
            }
        }
    }
    
}

extension QuizzGroupsVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if isQuizList != nil, isQuizList == true {
                let quizToDelete = quizzes[indexPath.row]
                FirebaseUser.shared.deleteQuiz(quiz: quizToDelete) { result in
                    switch result {
                    case .success:
                        print("Quiz successfully removed")
                        tableView.reloadData()
                    case .failure(let error):
                        print("Error removing quiz : \(error.localizedDescription)")
                    }
                }
            } else {
                let groupToDelete = groups[indexPath.row]
                FirebaseUser.shared.deleteGroup(group: groupToDelete) { result in
                    switch result {
                    case .success:
                        print("Group successfully removed")
                        tableView.reloadData()
                    case .failure(let error):
                        print("Error removing group : \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 70.0 // Remplacer par la hauteur désirée
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Désélectionnez la cellule pour une meilleure expérience utilisateur
        
        if isQuizList != nil, isQuizList == true  {
            let selectedQuiz = quizzes[indexPath.row]
            print("Selected quiz : \(selectedQuiz)")
            performSegue(withIdentifier: "goToModification", sender: selectedQuiz)
            
        } else {
            let selectedGroup = groups[indexPath.row]
            print("Selected group : \(selectedGroup)")
            performSegue(withIdentifier: "goToModification", sender: selectedGroup)
        }
    }
}


extension QuizzGroupsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isQuizList != nil, isQuizList == true  {
            return quizzes.count
        }else{
            return groups.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomCell
        if isQuizList != nil, isQuizList == true  {
            cell.label.text = quizzes[indexPath.row].name
        }else{
            cell.label.text = groups[indexPath.row].name
        }
//        cell.accessoryType = .disclosureIndicator
        let whiteDisclosureIndicator = UIImageView(image: UIImage(named: "whiteCustomDisclosureIndicator")) // Remplacez "customDisclosureIndicator" par le nom de votre image.
        whiteDisclosureIndicator.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        cell.accessoryView = whiteDisclosureIndicator
        
        return cell
    }
    
    
    
}


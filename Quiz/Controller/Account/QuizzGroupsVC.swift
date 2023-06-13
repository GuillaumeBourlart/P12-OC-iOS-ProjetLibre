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
                    print("Erreur lors de la récupération des quizz : \(error.localizedDescription)")
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
                    print("Erreur lors de la récupération des groupes : \(error.localizedDescription)")
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
        let alert = UIAlertController(title: "Ajouter un quizz", message: "Entrez le nom, la catégorie et la difficulté du quizz", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Nom"
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Catégorie"
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Difficulté"
        }
        
        let addAction = UIAlertAction(title: "Ajouter", style: .default) { (_) in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let category = alert.textFields?[1].text, !category.isEmpty,
                  let difficulty = alert.textFields?[2].text, !difficulty.isEmpty else { return }
            
            FirebaseUser.shared.addQuiz(name: name, category_id: category, difficulty: difficulty) { result in
                switch result {
                case .success():
                    print("Quiz ajouté avec succès.")
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Erreur lors de l'ajout du quiz : \(error.localizedDescription)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Annuler", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func displayAddGroupAlert() {
        let alert = UIAlertController(title: "Ajouter un groupe", message: "Entrez le nom du groupe", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Nom"
        }
        
        let addAction = UIAlertAction(title: "Ajouter", style: .default) { (_) in
            guard let name = alert.textFields?[0].text, !name.isEmpty else { return }
            
            FirebaseUser.shared.addGroup(name: name) { result in
                switch result {
                case .success():
                    print("Groupe ajouté avec succès.")
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Erreur lors de l'ajout du groupe : \(error.localizedDescription)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Annuler", style: .cancel)
        
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
                        print("Quiz supprimé avec succès.")
                        tableView.reloadData()
                    case .failure(let error):
                        print("Erreur lors de la suppression du quiz : \(error.localizedDescription)")
                    }
                }
            } else {
                let groupToDelete = groups[indexPath.row]
                FirebaseUser.shared.deleteGroup(group: groupToDelete) { result in
                    switch result {
                    case .success:
                        print("Groupe d'amis supprimé avec succès.")
                        tableView.reloadData()
                    case .failure(let error):
                        print("Erreur lors de la suppression du groupe d'amis : \(error.localizedDescription)")
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
            print("Informations du quiz sélectionné : \(selectedQuiz)")
            performSegue(withIdentifier: "goToModification", sender: selectedQuiz)
            
        } else {
            let selectedGroup = groups[indexPath.row]
            print("Informations du groupe sélectionné : \(selectedGroup)")
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
        cell.configure(isFriendCell: false, cellType: .none)
        
        return cell
    }
    
    
    
}


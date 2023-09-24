//
//  File.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 24/04/2023.
//

import Foundation
import UIKit

// Class to see every created quizzes of user
class QuizzesVC: UIViewController{
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    // Properties
    var quizzes: [Quiz] { return FirebaseUser.shared.userQuizzes ?? [] } // Store user's quizzes
    var activeAlert: UIAlertController? // For alert displaying
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Method called when view will appear
    override func viewWillAppear(_ animated: Bool) {
        // get all user's quizzes
        FirebaseUser.shared.getUserQuizzes { result in
            switch result {
            case .success():
                self.tableView.reloadData()
            case .failure(let error):
                print("Error getting quizzes : \(error.localizedDescription)")
            }
        }
    }
    
    // Method called when view will disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // If an alert is being displayed, dismiss it
        if let activeAlert = activeAlert {
            activeAlert.dismiss(animated: false)
            self.activeAlert = nil
        }
    }
    
    // display an alert
    @IBAction func plusButtonTapped(_ sender: Any) {
        displayAddQuizAlert()
    }
    
    // create an alert so user can create a quiz
    func displayAddQuizAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Add a quiz", comment: ""), message: NSLocalizedString("Enter name, category and difficulty", comment: ""), preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Name", comment: "")
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Category", comment: "")
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Difficulty", comment: "")
            textField.autocorrectionType = .no
        }
        
        let addAction = UIAlertAction(title: NSLocalizedString("Add", comment: ""), style: .default) { (_) in
            guard let name = alert.textFields?[0].text, !name.isEmpty,
                  let category = alert.textFields?[1].text, !category.isEmpty,
                  let difficulty = alert.textFields?[2].text, !difficulty.isEmpty else { return }
            
            FirebaseUser.shared.addQuiz(name: name, category_id: category, difficulty: difficulty) { result in
                switch result {
                case .success():
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error adding quiz : \(error.localizedDescription)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        self.activeAlert = alert
        present(alert, animated: true)
    }
    
    // Called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ModifyQuizVC {
            if let quiz = sender as? Quiz{
                destination.quizID = quiz.id
            }
        }
    }
    
}

extension QuizzesVC: UITableViewDelegate {
    
    // Handle deletion of a row in the table view
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // Get the quiz to be deleted
            let quizToDelete = quizzes[indexPath.row]
            
            // Delete the quiz using FirebaseUser's deleteQuiz function
            FirebaseUser.shared.deleteQuiz(quiz: quizToDelete) { result in
                switch result {
                case .success:
                    // Reload the table view after successful deletion
                    tableView.reloadData()
                case .failure(let error):
                    print("Error removing quiz: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Set the height for each row in the table view
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    // Handle row selection in the table view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Get the selected quiz
        let selectedQuiz = quizzes[indexPath.row]
        
        // Perform segue to modify the selected quiz
        performSegue(withIdentifier: "goToModification", sender: selectedQuiz)
    }
}

extension QuizzesVC: UITableViewDataSource {
    
    // Define the number of rows in the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quizzes.count
    }
    
    // Configure and return a cell for a specific row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomCell
        
        // Set the label text to the name of the quiz
        cell.label.text = quizzes[indexPath.row].name
        
        // Create a disclosure indicator for the cell
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

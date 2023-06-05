//
//  AddQuestionVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 03/06/2023.
//

import Foundation
import UIKit

class AddQuestionVC: UIViewController {
    
    
    @IBOutlet weak var validateButton: UIButton!
    @IBOutlet weak var questionField: UITextField!
    @IBOutlet weak var correctAnswerField: UITextField!
    @IBOutlet var incorrectAnswersFields: [UITextField]!
    @IBOutlet weak var explanationField: UITextField!
    
    var existingQuestion: UniversalQuestion?
    var existingQuestionId: String?
    var quiz: Quiz?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadExistingQuestion()
    }
    
    
    func loadExistingQuestion(){
        if let existingQuestion = existingQuestion {
            questionField.text = existingQuestion.question
            correctAnswerField.text = existingQuestion.correct_answer
            incorrectAnswersFields[0].text = existingQuestion.incorrect_answers[0]
            incorrectAnswersFields[1].text = existingQuestion.incorrect_answers[1]
            incorrectAnswersFields[2].text = existingQuestion.incorrect_answers[2]
            explanationField.text = existingQuestion.explanation
        }
    }
    
    @IBAction func validateButtonPressed(_ sender: Any) {
        guard let question = questionField.text, !question.isEmpty,
              let correctAnswer = correctAnswerField.text, !correctAnswer.isEmpty,
              let incorrectAnswer1 = incorrectAnswersFields[0].text, !incorrectAnswer1.isEmpty,
              let incorrectAnswer2 = incorrectAnswersFields[1].text, !incorrectAnswer2.isEmpty,
              let incorrectAnswer3 = incorrectAnswersFields[2].text, !incorrectAnswer3.isEmpty,
              let explanation = explanationField.text, !explanation.isEmpty
        else {
            // vous pouvez afficher un message d'erreur ici
            print("Tous les champs doivent être remplis.")
            return
        }
        
        if let existingQuestion = existingQuestion,let existingQuestionId = existingQuestionId {
            FirebaseUser.shared.updateQuestionInQuiz(quiz: self.quiz!, oldQuestionId: existingQuestionId, newQuestionText: question, correctAnswer: correctAnswer, incorrectAnswers: [incorrectAnswer1, incorrectAnswer2, incorrectAnswer3], explanation: explanation) { result in
                switch result {
                case .success():print("question ajouté")
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    print("Erreur lors de la mise à jour de la question : \(error)")
                }
            }
        } else {
            FirebaseUser.shared.addQuestionToQuiz(quiz: self.quiz!, questionText: question, correctAnswer: correctAnswer, incorrectAnswers: [incorrectAnswer1, incorrectAnswer2, incorrectAnswer3], explanation: explanation) { result in
                switch result {
                case .success():print("question ajoutées")
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    print("Erreur lors de l'ajout de la question : \(error)")
                }
            }
        }
    }
    
}

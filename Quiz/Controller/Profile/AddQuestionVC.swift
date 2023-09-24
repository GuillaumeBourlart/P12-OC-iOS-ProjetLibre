//
//  AddQuestionVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 03/06/2023.
//

import Foundation
import UIKit

// Class to create of modify a question for the selected quiz
class AddQuestionVC: UIViewController {
    // Outlets
    @IBOutlet weak var validateButton: UIButton!
    @IBOutlet weak var questionField: CustomTextField!
    @IBOutlet weak var correctAnswerField: CustomTextField!
    @IBOutlet var incorrectAnswersFields: [CustomTextField]!
    @IBOutlet weak var explanationField: CustomTextField!
    // Properties
    var existingQuestion: UniversalQuestion? // current question informations if user is modifying existing question
    var existingQuestionId: String? // current question ID if user is modifying existing question
    var quiz: Quiz? // Current quiz
    var activeTextField: UITextField? // For alert displaying
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        loadExistingQuestion()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardAppear(_:)), name: UIViewController.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDisappear(_:)), name: UIViewController.keyboardWillHideNotification, object: nil)
        
        setUI()
    }
    
    // Method to load the selected question if it exist, else user is creating a new question
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
    
    // Create or save the question and add it to the quiz
    @IBAction func validateButtonPressed(_ sender: Any) {
        CustomAnimations.buttonPressAnimation(for: self.validateButton) {
            
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            
            self.validateButton.isEnabled = false
            guard let question = self.questionField.text, !question.isEmpty,
                  let correctAnswer = self.correctAnswerField.text, !correctAnswer.isEmpty,
                  let incorrectAnswer1 = self.incorrectAnswersFields[0].text, !incorrectAnswer1.isEmpty,
                  let incorrectAnswer2 = self.incorrectAnswersFields[1].text, !incorrectAnswer2.isEmpty,
                  let incorrectAnswer3 = self.incorrectAnswersFields[2].text, !incorrectAnswer3.isEmpty,
                  let explanation = self.explanationField.text, !explanation.isEmpty
            else {
                print("At least on field is empty")
                self.validateButton.isEnabled = true
                return
            }
            
            if self.existingQuestion != nil , let existingQuestionId = self.existingQuestionId, let quiz = self.quiz {
                FirebaseUser.shared.updateQuestionInQuiz(quiz: quiz, oldQuestionId: existingQuestionId, newQuestionText: question, correctAnswer: correctAnswer, incorrectAnswers: [incorrectAnswer1, incorrectAnswer2, incorrectAnswer3], explanation: explanation) { result in
                    switch result {
                    case .success():
                        self.navigationController?.popViewController(animated: true)
                    case .failure(let error):
                        print(error)
                        self.validateButton.isEnabled = true
                    }
                }
            } else if let quiz = self.quiz {
                FirebaseUser.shared.addQuestionToQuiz(quiz: quiz, questionText: question, correctAnswer: correctAnswer, incorrectAnswers: [incorrectAnswer1, incorrectAnswer2, incorrectAnswer3], explanation: explanation) { result in
                    switch result {
                    case .success():
                        self.navigationController?.popViewController(animated: true)
                    case .failure(let error):
                        print(error)
                        self.validateButton.isEnabled = true
                    }
                }
            } else {
                self.validateButton.isEnabled = true
            }
        }
        
    }
    // Handle keyboard dismissing
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        questionField.resignFirstResponder()
        correctAnswerField.resignFirstResponder()
        incorrectAnswersFields[0].resignFirstResponder()
        incorrectAnswersFields[1].resignFirstResponder()
        incorrectAnswersFields[2].resignFirstResponder()
        explanationField.resignFirstResponder()
    }
    
    // update fields UI
    func setUI() {
        // Question
        questionField.setup(image: UIImage(systemName: "questionmark"), placeholder: NSLocalizedString("Question", comment: ""), placeholderColor: UIColor(named: "placeholder") ?? .gray)
        
        // CORRECT ANSWER
        correctAnswerField.setup(image: UIImage(systemName: "checkmark"), placeholder: NSLocalizedString("Correct answer", comment: ""), placeholderColor: UIColor(named: "placeholder") ?? .lightGray)
        
        // INCORRECT ANSWER 1
        incorrectAnswersFields[0].setup(image: UIImage(systemName: "1.circle"), placeholder: NSLocalizedString("Incorrect answer 1", comment: ""), placeholderColor: UIColor(named: "placeholder") ?? .lightGray)
        
        // INCORRECT ANSWER 2
        incorrectAnswersFields[1].setup(image: UIImage(systemName: "2.circle"), placeholder: NSLocalizedString("Incorrect answer 2", comment: ""), placeholderColor: UIColor(named: "placeholder") ?? .lightGray)
        
        // INCORRECT ANSWER 3
        incorrectAnswersFields[2].setup(image: UIImage(systemName: "3.circle"), placeholder: NSLocalizedString("Incorrect answer 3", comment: ""), placeholderColor: UIColor(named: "placeholder") ?? .lightGray)
        
        // Explanation
        explanationField.setup(image: UIImage(systemName: "book"), placeholder: NSLocalizedString("Explanation", comment: ""), placeholderColor: UIColor(named: "placeholder") ?? .lightGray)
    }
    
}
extension AddQuestionVC: UITextFieldDelegate {
    
    // Handle the return key on text fields to resign first responder status
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        questionField.resignFirstResponder()
        correctAnswerField.resignFirstResponder()
        incorrectAnswersFields[0].resignFirstResponder()
        incorrectAnswersFields[1].resignFirstResponder()
        incorrectAnswersFields[2].resignFirstResponder()
        explanationField.resignFirstResponder()
        return true
    }
    
    // Handle appearance of the keyboard and make view higher so we can see what we are writing
    @objc func keyboardAppear(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIViewController.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = frame.cgRectValue
        guard let activeTextField = activeTextField else { return }
        let activeTextFieldFrame = activeTextField.convert(activeTextField.bounds, to: self.view)
        
        if self.view.frame.origin.y == 0 && activeTextFieldFrame.maxY > keyboardFrame.origin.y {
            self.view.frame.origin.y -= activeTextFieldFrame.maxY - keyboardFrame.origin.y + 20 // +20 for a little extra space
        }
    }
    
    // Handle disappearance of the keyboard
    @objc func keyboardDisappear(_ notification: Notification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    // Handle the beginning of editing for a text field and store the active textfield
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
}

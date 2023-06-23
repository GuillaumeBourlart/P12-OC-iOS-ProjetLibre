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
    var activeTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadExistingQuestion()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardAppear(_:)), name: UIViewController.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDisappear(_:)), name: UIViewController.keyboardWillHideNotification, object: nil)
        
        setUI()
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
        CustomAnimations.buttonPressAnimation(for: self.validateButton) {
            
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
    
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        questionField.resignFirstResponder()
        correctAnswerField.resignFirstResponder()
        incorrectAnswersFields[0].resignFirstResponder()
        incorrectAnswersFields[1].resignFirstResponder()
        incorrectAnswersFields[2].resignFirstResponder()
        explanationField.resignFirstResponder()
    }
    
    func setUI(){
        // Question
        var imageView = UIImageView(image: UIImage(systemName: "questionmark"))
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
        
       
        
        // Définition du placeholder en gris clair
        let attributedPlaceholder = NSAttributedString(string: "Question", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        questionField.attributedPlaceholder = attributedPlaceholder
        
        var view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20)) // Augmentez la largeur de la vue
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20) // Centrez l'image dans la vue
        
        view.addSubview(imageView)
        
        questionField.leftViewMode = .always
        questionField.leftView = view
        
        // CORRECT ANSWER
        
        imageView = UIImageView(image: UIImage(systemName: "checkmark"))
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
        
      
        
        // Définition du placeholder en gris clair
        let attributedPlaceholder2 = NSAttributedString(string: "Correct answer", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        correctAnswerField.attributedPlaceholder = attributedPlaceholder2
        
        view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20)) // Augmentez la largeur de la vue
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20) // Centrez l'image dans la vue
        
        view.addSubview(imageView)
        correctAnswerField.leftViewMode = .always
        correctAnswerField.leftView = view
        
        // INCORRECT ANSWER 1
        
        imageView = UIImageView(image: UIImage(systemName: "1.circle"))
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
        
        
        
        // Définition du placeholder en gris clair
        let attributedPlaceholder3 = NSAttributedString(string: "Incorrect answer 1", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        incorrectAnswersFields[0].attributedPlaceholder = attributedPlaceholder3
        
        view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20)) // Augmentez la largeur de la vue
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20) // Centrez l'image dans la vue
        
        view.addSubview(imageView)
        incorrectAnswersFields[0].leftViewMode = .always
        incorrectAnswersFields[0].leftView = view
        
        // INCORRECT ANSWER 2
        
        imageView = UIImageView(image: UIImage(systemName: "2.circle"))
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
        
        
        
        // Définition du placeholder en gris clair
        let attributedPlaceholder4 = NSAttributedString(string: "Incorrect answer 2", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        incorrectAnswersFields[1].attributedPlaceholder = attributedPlaceholder4
        
        view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20)) // Augmentez la largeur de la vue
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20) // Centrez l'image dans la vue
        
        view.addSubview(imageView)
        incorrectAnswersFields[1].leftViewMode = .always
        incorrectAnswersFields[1].leftView = view
        
        // INCORRECT ANSWER 3
        
        imageView = UIImageView(image: UIImage(systemName: "3.circle"))
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
        
        
        
        // Définition du placeholder en gris clair
        let attributedPlaceholder5 = NSAttributedString(string: "Incorrect answer 3", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        incorrectAnswersFields[2].attributedPlaceholder = attributedPlaceholder5
        
        view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20)) // Augmentez la largeur de la vue
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20) // Centrez l'image dans la vue
        
        view.addSubview(imageView)
        incorrectAnswersFields[2].leftViewMode = .always
        incorrectAnswersFields[2].leftView = view
        
        // EXPLANATION
        
        imageView = UIImageView(image: UIImage(systemName: "book"))
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
        
        
        
        // Définition du placeholder en gris clair
        let attributedPlaceholder6 = NSAttributedString(string: "Explanation", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        explanationField.attributedPlaceholder = attributedPlaceholder6
        
        view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20)) // Augmentez la largeur de la vue
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20) // Centrez l'image dans la vue
        
        view.addSubview(imageView)
        explanationField.leftViewMode = .always
        explanationField.leftView = view
    }
    
}
extension AddQuestionVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        questionField.resignFirstResponder()
        correctAnswerField.resignFirstResponder()
        incorrectAnswersFields[0].resignFirstResponder()
        incorrectAnswersFields[1].resignFirstResponder()
        incorrectAnswersFields[2].resignFirstResponder()
        explanationField.resignFirstResponder()
        return true
    }
    
    @objc func keyboardAppear(_ notification: Notification) {
           guard let frame = notification.userInfo?[UIViewController.keyboardFrameEndUserInfoKey] as? NSValue else { return }
           let keyboardFrame = frame.cgRectValue
           guard let activeTextField = activeTextField else { return }
           let activeTextFieldFrame = activeTextField.convert(activeTextField.bounds, to: self.view)
           
           if self.view.frame.origin.y == 0 && activeTextFieldFrame.maxY > keyboardFrame.origin.y {
               self.view.frame.origin.y -= activeTextFieldFrame.maxY - keyboardFrame.origin.y + 20 // +20 for a little extra space
           }
       }
       
       @objc func keyboardDisappear(_ notification: Notification) {
           if self.view.frame.origin.y != 0 {
               self.view.frame.origin.y = 0
           }
       }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
}

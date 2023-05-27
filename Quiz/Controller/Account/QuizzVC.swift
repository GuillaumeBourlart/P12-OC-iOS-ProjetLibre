//
//  Quizz.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 22/04/2023.
//

import Foundation
import UIKit

class QuizzVC: UIViewController {
    
    var gameID: String?
    var userAnswers: [String: UserAnswer] = [:]
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet var answerButtons: [UIButton]!
    
    var questions: [UniversalQuestion] = []
    var currentQuestionIndex = 0
    var timer: Timer?
    var timeRemaining = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadQuestions()
    }
    
    func loadQuestions() {
            Game.shared.getQuestions(gameId: gameID!) { result in
                switch result {
                case .success(let questions):
                    self.questions = questions
                    print("après la closure : \(questions)")
                    self.displayQuestion()
                case .failure(let error):
                    print(error)
                }
            }
        }
        
        func displayQuestion() {
            if currentQuestionIndex >= questions.count {
                finishQuiz()
                return
            }
            
            let question = questions[currentQuestionIndex]
            questionLabel.text = question.question
            
            var choices = question.incorrect_answers + [question.correct_answer]
            choices.shuffle()
            
            for (index, button) in answerButtons.enumerated() {
                button.setTitle(choices[index], for: .normal)
                button.backgroundColor = .systemBlue
            }
            
            resetTimer()
        }
        
        func resetTimer() {
            timeRemaining = 10
            timerLabel.text = "\(timeRemaining)"
            
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                self.timeRemaining -= 1
                self.timerLabel.text = "\(self.timeRemaining)"
                
                if self.timeRemaining == 0 {
                    timer.invalidate()
                    self.showCorrectAnswerAndProceed()
                }
            }
        }
    
    @IBAction func answerButtonTapped(_ sender: UIButton) {
        let selectedAnswer = sender.currentTitle!
            let correctAnswer = questions[currentQuestionIndex].correct_answer
            let questionId = questions[currentQuestionIndex].id // Assuming your questions have an 'id' field

        let userAnswer = UserAnswer(selected_answer: selectedAnswer, points: selectedAnswer == correctAnswer ? 1 : 0)
            
        userAnswers[questionId!] = userAnswer
                
        
        sender.backgroundColor = selectedAnswer == correctAnswer ? .systemGreen : .systemRed
        
        timer?.invalidate()
        
        
            self.showCorrectAnswerAndProceed()
        
    }
    
    func showCorrectAnswerAndProceed() {
        let correctAnswer = questions[currentQuestionIndex].correct_answer
        for button in answerButtons {
            if button.currentTitle == correctAnswer {
                button.backgroundColor = .systemGreen
            } else {
                button.backgroundColor = .systemRed
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.currentQuestionIndex += 1
            self.displayQuestion()
        }
    }
    
    func finishQuiz() {
        // Naviguez vers un écran de résultats ou effectuez d'autres actions pour terminer le quizz
        print("Quizz terminé")
        Game.shared.saveStats(userAnswers: userAnswers, gameID: gameID!){ result in
            switch result {
            case .success():
                print("Statistiques enregistrés avec succès")
                self.performSegue(withIdentifier: "goToResult", sender: self.gameID!)
            case .failure(let error):
                print("Erreur lors de l'enregistrement des statistiques': \(error.localizedDescription)")
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ResultVC {
            if let gameID = sender as? String {
                destination.gameID = gameID
                destination.isResultAfterGame = true
            }
        }
    }
}


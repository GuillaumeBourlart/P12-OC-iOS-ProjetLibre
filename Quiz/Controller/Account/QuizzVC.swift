//
//  Quizz.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 22/04/2023.
//

import Foundation
import UIKit

class QuizzVC: UIViewController {
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet var answerButtons: [UIButton]!
    @IBOutlet weak var leaveButton: CustomButton!
    
    var gameID: String?
    var userAnswers: [String: UserAnswer] = [:]
    var isCompetitive: Bool = false
    var questions: [UniversalQuestion] = []
    var currentQuestionIndex = 0
    var timer: Timer?
    var timeRemaining = 10
    var isAnswering = false // Ajoutez cette variable
    var finalScore = 0
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadQuestions()
        navigationController?.setNavigationBarHidden(true, animated: true)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func loadQuestions() {
        Game.shared.getQuestions(quizId: nil, gameId: gameID!) { result in
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
        
        questionLabel.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        UIView.animate(withDuration: 0.5, animations: {
            self.questionLabel.transform = CGAffineTransform.identity
            self.appDelegate.playSoundEffect(soundName: "slide", fileType: "mp3")
        })
        
        questionLabel.text = question.question
        
        var choices = question.incorrect_answers + [question.correct_answer]
        choices.shuffle()
        
        for (index, button) in answerButtons.enumerated() {
            button.transform = index % 2 == 0 ? CGAffineTransform(translationX: -self.view.bounds.width, y: 0) : CGAffineTransform(translationX: self.view.bounds.width, y: 0)
            UIView.animate(withDuration: 0.5, delay: Double(index) * 0.2, options: [], animations: {
                button.transform = .identity
            }, completion: nil)
            button.setTitle(choices[index], for: .normal)
            button.backgroundColor = .systemBlue
        }
        
        resetTimer()
        isAnswering = false
    }
    
        
    @IBAction func leaveGame(_ sender: UIButton) {
        CustomAnimations.buttonPressAnimation(for: self.leaveButton) {
            self.leaveButton.isEnabled = false
            if let gameID = self.gameID {
                Game.shared.leaveGame(gameId: gameID){ result in
                    switch result {
                    case .failure(let error):
                        print(error)
                        self.leaveButton.isEnabled = true
                    case .success():
                        if self.isCompetitive != nil, self.isCompetitive == true {
                            // Dismiss the view controller
                            self.performSegue(withIdentifier: "unwindToCompetitive", sender: self)
                            
                        } else {
                            if let navController = self.navigationController {
                                var canUnwindToOpponentChoice = false

                                for controller in navController.viewControllers {
                                    if controller is OpponentChoice {
                                        // OpponentChoice est dans la pile de navigation
                                        canUnwindToOpponentChoice = true
                                        break // Sort de la boucle une fois OpponentChoice trouvé
                                    }
                                }

                                if canUnwindToOpponentChoice {
                                    // Si OpponentChoice est dans la pile de navigation, effectue l'unwind segue vers OpponentChoice
                                    print("unwindToOpponentChoice")
                                    self.performSegue(withIdentifier: "unwindToOpponentChoice", sender: self)
                                } else {
                                    // Si OpponentChoice n'est pas dans la pile de navigation, effectue l'unwind segue vers Invites
                                    print("unwindToInvites")
                                    self.performSegue(withIdentifier: "unwindToInvites", sender: self)
                                }
                            }else{
                                print("error")
                                self.leaveButton.isEnabled = true
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func resetTimer() {
        self.timerLabel.textColor = UIColor.white
        timeRemaining = 10
        timerLabel.text = "\(timeRemaining)"
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.timeRemaining -= 1
            self.timerLabel.text = "\(self.timeRemaining)"
            
            // Modifier l'aspect du label ici
            if self.timeRemaining <= 3 {
                self.timerLabel.textColor = UIColor.red
                
                // Animation pour grossir et rétrécir le texte
                UIView.animate(withDuration: 0.2,
                               animations: {
                                   self.timerLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                               },
                               completion: { _ in
                                   UIView.animate(withDuration: 0.2) {
                                       self.timerLabel.transform = CGAffineTransform.identity
                                   }
                    self.appDelegate.playSoundEffect(soundName: "beep", fileType: "mp3")
                               })
            }
            
            if self.timeRemaining == 0 {
                timer.invalidate()
                self.showCorrectAnswerAndProceed()
            }
        }
    }
    
    @IBAction func answerButtonTapped(_ sender: UIButton) {
        guard !isAnswering else { return } // Ignorez l'appui sur le bouton si l'utilisateur répond déjà à une question
                isAnswering = true // Définissez isAnswering à vrai lorsque l'utilisateur sélectionne une réponse
        guard let selectedAnswer = sender.currentTitle else { print("error"); return }
        let correctAnswer = questions[currentQuestionIndex].correct_answer

        guard let questionId = questions[currentQuestionIndex].id else { print("error"); return }
// Assuming your questions have an 'id' field

        let userAnswer = UserAnswer(selected_answer: selectedAnswer, points: selectedAnswer == correctAnswer ? 1 : 0)
        finalScore += selectedAnswer == correctAnswer ? 1 : 0
        if selectedAnswer == correctAnswer {
            appDelegate.playSoundEffect(soundName: "correct", fileType: "mp3")
        }else{
            appDelegate.playSoundEffect(soundName: "incorrect", fileType: "mp3")
        }
        userAnswers[questionId] = userAnswer
                
        
        sender.backgroundColor = selectedAnswer == correctAnswer ? .systemGreen : .systemRed
        
        timer?.invalidate()
        
        
            self.showCorrectAnswerAndProceed()
        
    }
    
   
    
    @objc func showCorrectAnswerAndProceed() {
        let correctAnswer = questions[currentQuestionIndex].correct_answer
        for button in answerButtons {
            if button.currentTitle == correctAnswer {
                button.backgroundColor = .systemGreen
            } else {
                button.backgroundColor = .systemRed
            }
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            self.questionLabel.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.currentQuestionIndex += 1
                self.displayQuestion()
            }
        }
    }
    
    func finishQuiz() {
        // Naviguez vers un écran de résultats ou effectuez d'autres actions pour terminer le quizz
        print("Quizz terminé")
        guard let gameId = gameID else { print("error"); return }
        Game.shared.saveStats(finalScore: finalScore, userAnswers: userAnswers, gameID: gameId){ result in
            switch result {
            case .success():
                print("Statistiques enregistrés avec succès")
                self.performSegue(withIdentifier: "goToResult", sender: gameId)
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


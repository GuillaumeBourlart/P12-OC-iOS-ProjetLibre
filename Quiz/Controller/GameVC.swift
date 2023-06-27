//
//  Quizz.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 22/04/2023.
//

import Foundation
import UIKit

class GameVC: UIViewController, LeavePageProtocol {
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
    var activeAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        loadQuestions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        questionLabel.layer.masksToBounds = true
        questionLabel.layer.cornerRadius = 15
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = false
        // If an alert is being displayed, dismiss it
               if let activeAlert = activeAlert {
                   activeAlert.dismiss(animated: false)
                   self.activeAlert = nil
               }
    }
    
    func leavePage(completion: @escaping () -> Void) {
        
            showLeaveConfirmation {
                self.leaveGame {
                    completion()
                }
            }
        
    }
    
    func setUpUI() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        tabBarController?.tabBar.isHidden = true
        
        resetAnimations()
    }
    
    func resetAnimations() {
        timer?.invalidate()
        questionLabel.layer.removeAllAnimations()
        timerLabel.layer.removeAllAnimations()
        for button in answerButtons {
            button.layer.removeAllAnimations()
        }
        appDelegate.soundEffectPlayer?.stop()
    }
    
  
    func loadQuestions() {
        Game.shared.getQuestions(quizId: nil, gameId: gameID!) { result in
            switch result {
            case .success(let questions):
                if let languageCode = Locale.current.languageCode, languageCode != "EN", languageCode != "en" {
                    translateQuestions(questions: questions, to: languageCode) { questions in
                        self.questions = questions
                        self.displayQuestion()
                    }
                } else {
                    self.questions = questions
                    self.displayQuestion()
                }
               
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func showLeaveConfirmation(completion: @escaping () -> Void) {
        let alert = UIAlertController(title: "Confirmation", message: "Êtes-vous sûr de vouloir quitter le quiz ?", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Oui", style: .destructive) { _ in
            completion()
        }
        let cancelAction = UIAlertAction(title: "Non", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        self.activeAlert = alert
        
        self.present(alert, animated: true)
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
        
        isAnswering = true // Bloquer les taps pendant les animations

        for (index, button) in answerButtons.enumerated() {
            button.transform = index % 2 == 0 ? CGAffineTransform(translationX: -self.view.bounds.width, y: 0) : CGAffineTransform(translationX: self.view.bounds.width, y: 0)
            button.setTitle(choices[index], for: .normal)
            button.backgroundColor = UIColor(named: "button")
            UIView.animate(withDuration: 0.5, delay: Double(index) * 0.2, options: [], animations: {
                button.transform = .identity
            }, completion: { _ in
                
                
                if index == self.answerButtons.count - 1 {
                    self.resetTimer()
                    self.isAnswering = false // Débloquer les taps après la dernière animation
                }
            })
        }
    }
    
    func showAlert(title: String, message: String, actionTitle: String, actionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: .default) { _ in
            actionHandler()
        }
        alertController.addAction(action)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func leavebuttonPressed(_ sender: Any) {
        showLeaveConfirmation {
               self.leaveGame {
               }
           }
    }
    
    func leaveGame(completion: @escaping () -> Void) {
        self.leaveButton.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: self.leaveButton) {
            self.leaveCurrentGame() {
                completion()
            }
            
        }
    }
    
    func leaveCurrentGame(completion: @escaping () -> Void) {
        guard let gameID = self.gameID else { return }
        Game.shared.leaveGame(gameId: gameID){ result in
            switch result {
            case .failure(let error):
                print(error)
                self.leaveButton.isEnabled = true
            case .success():
                self.navigateBackFromGame()
                completion()
            }
        }
    }
    
    func navigateBackFromGame() {
        if self.isCompetitive == true {
            self.performSegue(withIdentifier: "unwindToCompetitive", sender: self)
        } else {
            navigateToOpponentChoiceOrInvites()
        }
    }
    
    func navigateToOpponentChoiceOrInvites() {
        if let navController = self.navigationController {
            var canUnwindToOpponentChoice = false
            var canUnwindToInvites = false
            
            for controller in navController.viewControllers {
                if controller is OpponentChoice {
                    canUnwindToOpponentChoice = true
                    break
                }
            }
            
            for controller in navController.viewControllers {
                if controller is InvitesVC {
                    canUnwindToInvites = true
                    break
                }
            }
            
            if canUnwindToOpponentChoice {
                print("unwindToOpponentChoice")
                self.performSegue(withIdentifier: "unwindToOpponentChoice", sender: self)
            } else if canUnwindToInvites {
                print("unwindToInvites")
                self.performSegue(withIdentifier: "unwindToInvites", sender: self)
            } else {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                       print("Could not get app delegate")
                       return
                   }
                   if let viewControllers = appDelegate.mainTabBarController?.viewControllers {
                       print("Found \(viewControllers.count) view controllers in tab bar")
                       for viewController in viewControllers {
                           if let navigationController = viewController as? UINavigationController {
                               print("Found a navigation controller with \(navigationController.viewControllers.count) view controllers")
                               navigationController.popToRootViewController(animated: false)
                               print("After pop, it now has \(navigationController.viewControllers.count) view controllers")
                           } else {
                               print("Found a view controller that is not a navigation controller: \(viewController)")
                           }
                       }
                   } else {
                       print("mainTabBarController does not have any viewControllers")
                   }
            }
        } else {
            self.leaveButton.isEnabled = true
        }
    }
    
    func resetTimer() {
        self.timerLabel.textColor = UIColor(named: "text")
        timeRemaining = 10
        timerLabel.text = "\(timeRemaining)"
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.timeRemaining -= 1
            self.timerLabel.text = "\(self.timeRemaining)"
            
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
        
        let userAnswer = UserAnswer(selected_answer: selectedAnswer, points: selectedAnswer == correctAnswer ? 1*timeRemaining : 0)
        finalScore += selectedAnswer == correctAnswer ? 1*timeRemaining : 0
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.currentQuestionIndex += 1
                self.displayQuestion()
            }
        }
    }
    
    func finishQuiz() {
        guard let gameId = gameID else { print("error"); return }
        Game.shared.saveStats(finalScore: finalScore, userAnswers: userAnswers, gameID: gameId){ result in
            switch result {
            case .success():
                self.performSegue(withIdentifier: "goToResult", sender: gameId)
            case .failure(let error):
                print("Error saving stats': \(error.localizedDescription)")
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


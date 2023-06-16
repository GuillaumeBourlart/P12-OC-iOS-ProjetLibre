//
//  Quizz.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 22/04/2023.
//

import Foundation
import UIKit

class QuizzVC: UIViewController, LeavePageProtocol {
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
        setUpUI()
        loadQuestions()
    }
    
    func leavePage(completion: @escaping () -> Void) {
        leaveGame {
            completion()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        tabBarController?.tabBar.isHidden = false
        
        
    }
    
    func loadQuestions() {
        Game.shared.getQuestions(quizId: nil, gameId: gameID!) { result in
            switch result {
            case .success(let questions):
                print("après la closure : \(questions)")
                if let selectedLanguage = UserDefaults.standard.object(forKey: "SelectedLanguage") as? String, selectedLanguage != "EN" {
                    translateQuestions(questions: questions, to: selectedLanguage) { questions in
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
        leaveGame {
            print("Successfully left game")
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
                self.performSegue(withIdentifier: "unwindToHomeVC", sender: self)
            }
        } else {
            print("error")
            self.leaveButton.isEnabled = true
        }
    }
    
    func resetTimer() {
        self.timerLabel.textColor = UIColor.white
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


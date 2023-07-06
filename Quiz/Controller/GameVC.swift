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
    @IBOutlet weak var goodAnswerLabel: UILabel!
    
    var translator = DeepLTranslator(service: Service(networkRequest: AlamofireNetworkRequest()))
    var gameID: String?
    var userAnswers: [String: UserAnswer] = [:]
    var isCompetitive: Bool = false
    var questions: [UniversalQuestion] = []
    var currentQuestionIndex = 0
    var timer: Timer?
    var timeRemaining = 10
    var isAnswering = false 
    var finalScore = 0
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var activeAlert: UIAlertController?
    var confettiLayer: CAEmitterLayer!
    
    
    override func viewDidLoad() {
           super.viewDidLoad()
           setUpUI()
           loadQuestions()
           
           confettiLayer = createConfettiLayer()
           confettiLayer.birthRate = 0 // On désactive le confettiLayer par défaut.
           view.layer.addSublayer(confettiLayer)
       }
    
    func displayGoodAnswerLabel(){
        
        goodAnswerLabel.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        goodAnswerLabel.isHidden = false
        UIView.animate(withDuration: 0.5, animations: {
            self.goodAnswerLabel.transform = CGAffineTransform.identity
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.goodAnswerLabel.isHidden = true // On désactive le confettiLayer après 1 seconde.
            }
        })
    }

       func createConfettiLayer() -> CAEmitterLayer {
           let confettiLayer = CAEmitterLayer()

           confettiLayer.emitterPosition = CGPoint(x: view.frame.midX, y: -50)
           confettiLayer.emitterShape = .line
           confettiLayer.emitterSize = CGSize(width: view.frame.size.width, height: 2)

           let cell = CAEmitterCell()
           cell.birthRate = 15
           cell.lifetime = 14.0
           cell.velocity = CGFloat(350)
           cell.velocityRange = CGFloat(80)
           cell.emissionLongitude = CGFloat(Double.pi)
           cell.emissionRange = CGFloat(Double.pi/4)
           cell.spin = CGFloat(3.5)
           cell.spinRange = CGFloat(4.0)
           cell.scaleRange = CGFloat(0.05)
           cell.scale = 0.3
           cell.scaleSpeed = CGFloat(-0.1)
           cell.color = UIColor.green.cgColor

           // Mettez ici le nom de l'image que vous voulez utiliser pour les confettis.
           cell.contents = UIImage(systemName: "square.fill")?.cgImage
           

           confettiLayer.emitterCells = [cell]
           return confettiLayer
       }

       func showConfetti() {
           confettiLayer.birthRate = 15 // On active le confettiLayer.

           DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
               self.confettiLayer.birthRate = 0 // On désactive le confettiLayer après 1 seconde.
           }
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
                    self.translator.translateQuestions(questions: questions, to: languageCode) { questions in
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
        let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to leave the game ?", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            completion()
        }
        let cancelAction = UIAlertAction(title: "No", style: .cancel)
        
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
        questionLabel.isHidden = false
        questionLabel.text = question.question
        UIView.animate(withDuration: 0.5, animations: {
            self.questionLabel.transform = CGAffineTransform.identity
            self.appDelegate.playSoundEffect(soundName: "slide", fileType: "mp3")
        })
        
        
        
        var choices = question.incorrect_answers + [question.correct_answer]
        choices.shuffle()
        
        isAnswering = true
        
        for (index, button) in answerButtons.enumerated() {
            button.isHidden = false
            button.transform = index % 2 == 0 ? CGAffineTransform(translationX: -self.view.bounds.width, y: 0) : CGAffineTransform(translationX: self.view.bounds.width, y: 0)
            button.setTitle(choices[index], for: .normal)
            button.backgroundColor = UIColor(named: "button")
            UIView.animate(withDuration: 0.5, delay: Double(index) * 0.2, options: [], animations: {
                button.transform = .identity
            }, completion: { _ in
                
                
                if index == self.answerButtons.count - 1 {
                    self.resetTimer()
                    self.isAnswering = false
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
        timeRemaining = 10
        timerLabel.text = "\(timeRemaining)"
        timerLabel.textColor = .white
        timerLabel.isHidden = false
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.timeRemaining -= 1
            self.timerLabel.text = "\(self.timeRemaining)"
            
            // Changer la couleur du label en fonction du temps restant
            let colorValue = CGFloat(self.timeRemaining) / 10.0 // This will give us a value between 0 and 1
            self.timerLabel.textColor = UIColor(red: 1.0, green: colorValue, blue: colorValue, alpha: 1.0)
            
            // Changer la taille du label en fonction du temps restant
            let scale = 1.0 + (2.0 - colorValue) * 0.5 // This will give us a scale between 1.0 and 1.5
            
            // Animation pour grossir le texte
            UIView.animate(withDuration: 0.2,
                           animations: {
                self.timerLabel.transform = CGAffineTransform(scaleX: scale, y: scale)
            },
                           completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    self.timerLabel.transform = CGAffineTransform.identity
                }
                // Jouer le son seulement lors des trois dernières secondes
                if self.timeRemaining <= 3 {
                    self.appDelegate.playSoundEffect(soundName: "beep", fileType: "mp3")
                }
            })
            
            if self.timeRemaining == 0 {
                self.timerLabel.isHidden = true
                timer.invalidate()
                self.showCorrectAnswerAndProceed()
            }
        }
    }
    
    @IBAction func answerButtonTapped(_ sender: UIButton) {
        guard !isAnswering else { return }
        isAnswering = true
        timerLabel.isHidden = true
        guard let selectedAnswer = sender.currentTitle else { print("error"); return }
        let correctAnswer = questions[currentQuestionIndex].correct_answer
        
        guard let questionId = questions[currentQuestionIndex].id else { print("error"); return }
        
        
        let userAnswer = UserAnswer(selected_answer: selectedAnswer, points: selectedAnswer == correctAnswer ? 1*timeRemaining : 0)
        finalScore += selectedAnswer == correctAnswer ? 1*timeRemaining : 0
        if selectedAnswer == correctAnswer {
            appDelegate.playSoundEffect(soundName: "correct", fileType: "mp3")
        }else{
            appDelegate.playSoundEffect(soundName: "incorrect", fileType: "mp3")
        }
        userAnswers[questionId] = userAnswer
        
        
        sender.backgroundColor = selectedAnswer == correctAnswer ? .systemGreen : .systemRed
        if selectedAnswer == correctAnswer {
            showConfetti()
            displayGoodAnswerLabel()
        }
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


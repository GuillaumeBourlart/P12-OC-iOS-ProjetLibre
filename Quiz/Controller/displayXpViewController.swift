//
//  displayXpViewController.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 19/09/2023.
//

import Foundation
import UIKit

class displayXpViewControler: UIViewController {
    
    @IBOutlet weak var bar: UIProgressView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var currentXPLabel: UILabel!
    
    var isResultAfterGame: Bool?
    var gameID: String?
    
    override func viewWillAppear(_ animated: Bool) {
        if isResultAfterGame != nil, isResultAfterGame == true{
            navigationController?.setNavigationBarHidden(true, animated: true)
            tabBarController?.tabBar.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialisation
        bar.setProgress(0, animated: false)
        label.text = "0 xp"
        let currentXPString = NSLocalizedString("Current xp", comment: "Label for current XP")
        
        
        // Mettre à jour currentXPLabel
        if let currentXPValue = FirebaseUser.shared.userInfo?.points {
            currentXPLabel.text = "\(currentXPString) : \(currentXPValue)"
        }else{
            currentXPLabel.text = "\(currentXPString) : 0"
        }
        
        // Rendre la progress view plus épaisse
            bar.transform = bar.transform.scaledBy(x: 1, y: 6)
        
        // Démarre l'animation après un certain délai, si nécessaire
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.animateProgress()
        }
    }
    @IBAction func continueButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "goToResult", sender: gameID)
    }
    
    private func animateProgress() {
        // Durée de l'animation
        let animationDuration: TimeInterval = 1.5
        let moveAndFadeDuration: TimeInterval = 0.5
        
        // Capture la position initiale de label
           let initialLabelCenter = self.label.center
        
        // Animer la jauge de progression
        UIView.animate(withDuration: animationDuration, animations: {
            self.bar.setProgress(1.0, animated: true)
        })
        
        if let tabBar = self.tabBarController as? CustomTabBarController {
            tabBar.playSoundEffect(soundName: "money-counter", fileType: "mp3")
        }
        
        // Animer le label
        let xpStart = 0
        let xpEnd = 30
        var currentXP = xpStart
        let localizedCurrentXP = NSLocalizedString("Current xp", comment: "Label for current XP")
        
        Timer.scheduledTimer(withTimeInterval: animationDuration / Double(xpEnd - xpStart), repeats: true) { timer in
            currentXP += 1
            self.label.text = "\(currentXP) xp"
            
            // Arrêter le timer lorsque l'XP final est atteint
            if currentXP == xpEnd {
                timer.invalidate()
                
                print("Initial position of label: \(self.label.center)")
                print("Final position should be: \(self.currentXPLabel.center)")
                
                // Désactiver les contraintes Auto Layout si nécessaire
                self.label.translatesAutoresizingMaskIntoConstraints = true
                self.currentXPLabel.translatesAutoresizingMaskIntoConstraints = true
                
                // Animer le déplacement du label vers currentXPLabel
                UIView.animate(withDuration: moveAndFadeDuration, animations: {
                    self.label.center = self.currentXPLabel.center
                }) { _ in
                    // Faire disparaître le label
                    self.label.alpha = 0
                    
                    // Mettre à jour currentXPLabel
                    if let currentXPValue = FirebaseUser.shared.userInfo?.points {
                        self.currentXPLabel.text = "\(localizedCurrentXP) : \(currentXPValue + xpEnd)"
                        
                        // Après avoir mis à jour currentXPLabel, faire disparaître la barre de progression
                        UIView.animate(withDuration: 0.5, animations: {
                            
                        }) { _ in
                            // Placer currentXPLabel au bas de la vue supérieure
                            self.bar.alpha = 0
                            if let superview = self.currentXPLabel.superview {
                                let centerX = superview.bounds.midX
                                let bottomY = superview.bounds.maxY - self.currentXPLabel.frame.height / 2.0 // ajuster si nécessaire
                                UIView.animate(withDuration: 0.5, animations: {
                                    // Mettre le texte un peu plus gros
                                    self.currentXPLabel.font = self.currentXPLabel.font.withSize(self.currentXPLabel.font.pointSize + 2)
                                    // Déplacer le label
                                    self.currentXPLabel.center = CGPoint(x: centerX, y: bottomY)
                                    if let tabBar = self.tabBarController as? CustomTabBarController {
                                        tabBar.playSoundEffect(soundName: "slide", fileType: "mp3")
                                    }
                                }) { _ in
                                    Game.shared.updateXP { result in
                                        switch result {
                                        case .success(var Int): print("\(Int) points ajoutés")
                                        case .failure(let error): print(error)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ResultVC {
            if let gameID = sender as? String {
                destination.gameID = gameID
                destination.isResultAfterGame = isResultAfterGame
            }
        }
    }
    
    
    
}

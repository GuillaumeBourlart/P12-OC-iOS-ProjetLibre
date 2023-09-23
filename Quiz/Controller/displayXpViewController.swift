//
//  displayXpViewController.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 19/09/2023.
//

import Foundation
import UIKit
// Class to show XP earned after a game
class displayXpViewControler: UIViewController {
    // Outlets
    @IBOutlet weak var bar: UIProgressView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var currentXPLabel: UILabel!
    // Properties
    var isResultAfterGame: Bool?
    var gameID: String?
    
    // Method called when the view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialization
        bar.setProgress(0, animated: false)
        label.text = "0 xp"
        let currentXPString = NSLocalizedString("Current xp", comment: "Label for current XP")
        
        // Update currentXPLabel
        if let currentXPValue = FirebaseUser.shared.userInfo?.points {
            currentXPLabel.text = "\(currentXPString) : \(currentXPValue)"
        } else {
            currentXPLabel.text = "\(currentXPString) : 0"
        }
        
        // Make the progress view thicker
        bar.transform = bar.transform.scaledBy(x: 1, y: 6)
        
        // Start the animation after a certain delay, if necessary
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.animateProgress()
        }
    }

    // Method called when the view will appear
    override func viewWillAppear(_ animated: Bool) {
        if isResultAfterGame != nil, isResultAfterGame == true {
            navigationController?.setNavigationBarHidden(true, animated: true)
            tabBarController?.tabBar.isHidden = true
        }
    }
    
    // Action method called when the "Continue" button is pressed
    @IBAction func continueButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "goToResult", sender: gameID)
    }
    
    // Private method to animate the progress
    private func animateProgress() {
        // Animation duration
        let animationDuration: TimeInterval = 1.5
        let moveAndFadeDuration: TimeInterval = 0.5

        // Animate the progress bar
        UIView.animate(withDuration: animationDuration) {
            self.bar.setProgress(1.0, animated: true)
        }

        if let tabBar = self.tabBarController as? CustomTabBarController {
            tabBar.playSoundEffect(soundName: "money-counter", fileType: "mp3")
        }

        // Animate the label
        let xpStart = 0
        let xpEnd = 30
        var currentXP = xpStart
        let localizedCurrentXP = NSLocalizedString("Current xp", comment: "Label for current XP")

        Timer.scheduledTimer(withTimeInterval: animationDuration / Double(xpEnd - xpStart), repeats: true) { timer in
            currentXP += 1
            self.label.text = "\(currentXP) xp"

            // Stop the timer when the final XP is reached
            if currentXP == xpEnd {
                timer.invalidate()

                // Disable Auto Layout constraints if needed
                self.label.translatesAutoresizingMaskIntoConstraints = true
                self.currentXPLabel.translatesAutoresizingMaskIntoConstraints = true

                // Animate the label's movement to currentXPLabel
                UIView.animate(withDuration: moveAndFadeDuration, animations: {
                    self.label.center = self.currentXPLabel.center
                }) { _ in
                    
                    // Fade out the label
                    self.label.alpha = 0
                    
                    // Update currentXPLabel
                    if let currentXPValue = FirebaseUser.shared.userInfo?.points {
                        self.currentXPLabel.text = "\(localizedCurrentXP) : \(currentXPValue + xpEnd)"
                        
                        // After updating currentXPLabel, hide the progress bar
                        UIView.animate(withDuration: 0.5) {
                            self.bar.alpha = 0
                            if let superview = self.currentXPLabel.superview {
                                let centerX = superview.bounds.midX
                                let bottomY = superview.bounds.maxY - self.currentXPLabel.frame.height / 2.0
                                UIView.animate(withDuration: 0.5) {
                                    // Increase text size
                                    self.currentXPLabel.font = self.currentXPLabel.font.withSize(self.currentXPLabel.font.pointSize + 2)
                                    // Move the label
                                    self.currentXPLabel.center = CGPoint(x: centerX, y: bottomY)
                                    if let tabBar = self.tabBarController as? CustomTabBarController {
                                        tabBar.playSoundEffect(soundName: "slide", fileType: "mp3")
                                    }
                                } completion: { _ in
                                    Game.shared.updateXP { result in
                                        switch result {
                                        case .success(let Int): print("\(Int) xp added")
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

    // Method to prepare for a segue to ResultVC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ResultVC {
            if let gameID = sender as? String {
                destination.gameID = gameID
                destination.isResultAfterGame = isResultAfterGame
            }
        }
    }
    
    
    
}

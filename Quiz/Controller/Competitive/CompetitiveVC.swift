//
//  Ranked.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import Foundation
import UIKit


class CompetitiveVC: UIViewController{
    
    @IBOutlet weak var rankBar: UIProgressView!
    @IBOutlet weak var points: UILabel!
    @IBOutlet weak var previousRank: UIImageView!
    @IBOutlet weak var currentRank: UIImageView!
    @IBOutlet weak var nextRank: UIImageView!
    @IBOutlet weak var startButton: CustomButton2!
    
    @IBOutlet weak var rankView: UIView!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            updateUI()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            FirebaseUser.shared.getUserInfo { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success():
                    self.updateUI()
                }
            }
            self.startButton.isEnabled = true
        }
        
    func updateUI() {
        guard let rankValue = FirebaseUser.shared.userInfo?.rank else {
            return
        }
        
        let intValue = Int(rankValue)  // Convertir en Int
        let level = intValue / 10      // Obtenir le niveau
        let progress = intValue % 10   // Obtenir la progression
        
        guard let rank = Rank(rawValue: level) else {
            return
        }
        
        rankView.layer.cornerRadius = 15
        rankBar.progress = Float(progress) / 10.0
        points.text = "\(progress)/10"
        
        previousRank.tintColor = rank.previous?.color ?? UIColor.clear
        currentRank.tintColor = rank.color
        nextRank.tintColor = rank.next?.color ?? UIColor.clear
        
        if rank == .bests {
            nextRank.isHidden = true
            previousRank.isHidden = true
            rankBar.isHidden = true
            points.isHidden = true
        }
    }
    
    @IBAction func unwindToCompetitive(segue: UIStoryboardSegue) {
    }
    
    @IBAction func findOpponentButtonPressed(_ sender: Any) {
        self.startButton.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: self.startButton) {
            
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "goToFindOpponent", sender: self)
            }
        }
    }
}


enum Rank: Int {
    case bronze = 0
    case silver
    case gold
    case platinum
    case diamond
    case master
    case bests
    
    var color: UIColor {
        switch self {
                case .bronze: return UIColor(red: 230/255, green: 182/255, blue: 140/255, alpha: 1.0)
                case .silver: return UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0)
                case .gold: return UIColor(red: 255/255, green: 235/255, blue: 180/255, alpha: 1.0)
                case .platinum: return UIColor(red: 180/255, green: 225/255, blue: 240/255, alpha: 1.0)
                case .diamond: return UIColor(red: 180/255, green: 230/255, blue: 255/255, alpha: 1.0)
                case .master: return UIColor(red: 255/255, green: 180/255, blue: 255/255, alpha: 1.0)
                case .bests: return UIColor(red: 255/255, green: 215/255, blue: 180/255, alpha: 1.0)
        }
    }
    
    var next: Rank? {
        return Rank(rawValue: rawValue + 1)
    }
    
    var previous: Rank? {
        return Rank(rawValue: rawValue - 1)
    }
}


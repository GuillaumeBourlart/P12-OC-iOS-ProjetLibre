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
                   // Vous pouvez ajouter une gestion des erreurs plus robuste ici.
                   print(error)
               case .success():
                   self.updateUI()
               }
           }
           self.startButton.isEnabled = true
           
           navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
           navigationController?.navigationBar.shadowImage = UIImage()
           navigationController?.navigationBar.isTranslucent = true
           navigationController?.navigationBar.tintColor = UIColor(named: "text")
           navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "text") ?? UIColor.magenta]
       }
       
    func updateUI() {
        guard let rankValue = FirebaseUser.shared.userInfo?.rank else {
            return
        }
        
        let level = Int(rankValue)
        let progress = rankValue.truncatingRemainder(dividingBy: 1)
        
        guard let rank = Rank(rawValue: level) else {
            return
        }
        
        rankView.layer.cornerRadius = 15
        
        rankBar.progress = Float(progress)
        points.text = "\(Int(progress * 100))/100"
        
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
           // Vous pouvez utiliser cette méthode pour effectuer des actions lorsque l'unwind segue est exécuté.
       }
       
       @IBAction func findOpponentButtonPressed(_ sender: Any) {
           self.startButton.isEnabled = false
           CustomAnimations.buttonPressAnimation(for: self.startButton) {
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
        case .bronze: return UIColor(red: 205/255, green: 127/255, blue: 50/255, alpha: 1.0)
        case .silver: return UIColor(red: 192/255, green: 192/255, blue: 192/255, alpha: 1.0)
        case .gold: return UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0)
        case .platinum: return UIColor(red: 0/255, green: 150/255, blue: 200/255, alpha: 1.0)
        case .diamond: return UIColor(red: 0/255, green: 200/255, blue: 255/255, alpha: 1.0)
        case .master: return UIColor(red: 255/255, green: 0/255, blue: 255/255, alpha: 1.0)
        case .bests: return UIColor.orange
        }
    }
    
    var next: Rank? {
        return Rank(rawValue: rawValue + 1)
    }
    
    var previous: Rank? {
        return Rank(rawValue: rawValue - 1)
    }
}

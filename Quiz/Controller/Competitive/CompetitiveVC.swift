//
//  Ranked.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import Foundation
import FirebaseFirestore
import UIKit


class CompetitiveVC: UIViewController{
    // Outlets
    @IBOutlet weak var rankBar: UIProgressView!
    @IBOutlet weak var points: UILabel!
    @IBOutlet weak var previousRank: UIImageView!
    @IBOutlet weak var currentRank: UIImageView!
    @IBOutlet weak var nextRank: UIImageView!
    @IBOutlet weak var startButton: CustomButton2!
    @IBOutlet weak var rankView: UIView!
    //Properties
    var listener: ListenerRegistration?
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    // Method called when view will appear
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
        startListening()
    }
    
    // Method called when view will disapear
    override func viewWillDisappear(_ animated: Bool) {
        listener?.remove()
        listener = nil
    }
    
    // Method to update UI
    func updateUI() {
        
        
        
        
            guard let rankValue = FirebaseUser.shared.userInfo?.rank else {
                return
            }
            
            let intValue = Int(rankValue)  // Convertir en Int
            let level = intValue / 10      // Obtenir le niveau
            let progress = intValue % 10   // Obtenir la progression
        
       
        
        if level >= 7 {
                   // Gérez ici les niveaux supérieurs ou égaux à 7
                   nextRank.isHidden = true
                   previousRank.isHidden = true
                   rankBar.isHidden = true
                   points.text = "\(intValue) xp"
                   currentRank.image = UIImage(named: "level6") ?? UIImage(systemName: "star.fill")
                   return
               }
            
            guard let rank = Rank(rawValue: level) else {
                return
            }
            
            rankView.layer.cornerRadius = 15
            rankBar.progress = Float(progress) / 10.0
            points.text = "\(progress)/10"
            
            previousRank.image = rank.previous?.image ?? UIImage(systemName: "star.fill")
            currentRank.image = rank.image 
            nextRank.image = rank.next?.image ?? UIImage(systemName: "star.fill")
            
        if level >= 6 {
                    nextRank.isHidden = true
                    previousRank.isHidden = true
                    rankBar.isHidden = true
                    points.text = "\(intValue) xp"
        } else if level == 0 {
            nextRank.isHidden = false
            previousRank.isHidden = true
            rankBar.isHidden = false
            rankBar.progress = Float(progress) / 10.0
            points.text = "\(progress)/10"
            
        } else {
                    nextRank.isHidden = false
                    previousRank.isHidden = false
                    rankBar.isHidden = false
                    rankBar.progress = Float(progress) / 10.0
                    points.text = "\(progress)/10"
                }
        
        
        }
    
    // Method to animate UI when level change
    func makedisapearRankImages(progress: Int) {
        // Animer les éléments d'image pour rétrécir
        UIView.animate(withDuration: 0.5, animations: {
            self.nextRank.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                self.previousRank.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                self.currentRank.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }){ _ in
                self.restoreRankImagesToOriginalSize()
            }
           
    }
    
    func animateProgressView(progress: Int){
        
        // Animer la barre de progression
        let newProgress = Float(progress) / 10.0
        self.rankBar.setProgress(newProgress, animated: true)


        // Mettre à jour le label des points
        points.text = "\(progress)/10"
    }
    
    func restoreRankImagesToOriginalSize() {
        
        // Ensuite, animer les éléments pour revenir à leur taille originale
        UIView.animate(withDuration: 0.5, animations: {
            self.nextRank.transform = CGAffineTransform.identity
            self.previousRank.transform = CGAffineTransform.identity
            self.currentRank.transform = CGAffineTransform.identity
        })
    }
    
    // start listening for rank update and update UI if needed
    func startListening(){
        if let userID = FirebaseUser.shared.currentUserId {
            listener = Game.shared.ListenForChangeInDocument(in: "users", documentId: userID) { result in
                switch result {
                case .failure(let error): print(error)
                case .success(let data):
                    let newrank: Int = data["rank"] as! Int
                    guard FirebaseUser.shared.userInfo?.rank != newrank else {
                        return
                    }
                    FirebaseUser.shared.userInfo?.rank = newrank
                    let intValue = Int(newrank)  // Convertir en Int
                    let progress = intValue % 10
                    self.makedisapearRankImages(progress: progress)
                    self.animateProgressView(progress: progress)
                    self.updateUI()
                    
                }
            }
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
    
    var image: UIImage {
        switch self {
        case .bronze: return UIImage(named: "level0") ?? UIImage(systemName: "star.fill")!
                case .silver: return UIImage(named: "level1") ?? UIImage(systemName: "star.fill")!
                case .gold: return UIImage(named: "level2") ?? UIImage(systemName: "star.fill")!
                case .platinum: return UIImage(named: "level3") ?? UIImage(systemName: "star.fill")!
        case .diamond: return UIImage(named: "level4") ?? UIImage(systemName: "star.fill")!
        case .master: return UIImage(named: "level5") ?? UIImage(systemName: "star.fill")!
        case .bests: return UIImage(named: "level6") ?? UIImage(systemName: "star.fill")!
        }
    }
    
    var next: Rank? {
        return Rank(rawValue: rawValue + 1)
    }
    
    var previous: Rank? {
        return Rank(rawValue: rawValue - 1)
    }
}


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
    
    let colorBronze = UIColor(red: 205/255, green: 127/255, blue: 50/255, alpha: 1.0) // Bronze
    let colorSilver = UIColor(red: 192/255, green: 192/255, blue: 192/255, alpha: 1.0) // Argent
    let colorGold = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0) // Or
    let colorPlatinum = UIColor(red: 0/255, green: 150/255, blue: 200/255, alpha: 1.0) // Platine
    let colorDiamond = UIColor(red: 0/255, green: 200/255, blue: 255/255, alpha: 1.0) // Diamant
    let colorMaster = UIColor(red: 255/255, green: 0/255, blue: 255/255, alpha: 1.0) // Maître
    
    override func viewDidLoad() {
        
        // Masquer le bouton "back"
        //            self.navigationItem.hidesBackButton = true
        updateRank()
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        FirebaseUser.shared.getUserInfo { result in
            switch result {
            case .failure(let error): print(error)
            case .success(): self.updateRank()
            }
        }
    }
    
    func updateRank() {
        let rank = Double((FirebaseUser.shared.userInfo?.rank ?? 0))
        let level = Int(rank)
        let progress = rank.truncatingRemainder(dividingBy: 1) * 100
        DispatchQueue.main.async { [self] in
        
            self.rankBar.progress = Float(progress) / 100
            switch level {
            case 0: self.previousRank.tintColor = UIColor.clear
                self.nextRank.tintColor = self.colorSilver
                self.currentRank.tintColor = self.colorBronze
                
            case 1: self.previousRank.tintColor = self.colorBronze
                self.nextRank.tintColor = self.colorGold
                self.currentRank.tintColor = self.colorSilver
                
            case 2: self.previousRank.tintColor = self.colorSilver
                self.nextRank.tintColor = self.colorPlatinum
                self.currentRank.tintColor = self.colorGold
                
            case 3: self.previousRank.tintColor = self.colorGold
                self.nextRank.tintColor = self.colorDiamond
                self.currentRank.tintColor = self.colorPlatinum
                
            case 4: self.previousRank.tintColor = colorPlatinum
                self.nextRank.tintColor = self.colorMaster
                self.currentRank.tintColor = self.colorDiamond
                
            case 5: self.previousRank.tintColor = self.colorDiamond
                self.nextRank.tintColor = UIColor.clear
                self.currentRank.tintColor = self.colorMaster
                
            default:
                self.previousRank.tintColor = self.colorDiamond
                self.nextRank.tintColor = UIColor.clear
                self.currentRank.tintColor = self.colorMaster
            }
        }
        points.text = "\(Int(progress))/100"
    }
    
    @IBAction func unwindToCompetitive(segue: UIStoryboardSegue) {
        // Vous pouvez utiliser cette méthode pour effectuer des actions lorsque l'unwind segue est exécuté.
        
    }
    
    
}

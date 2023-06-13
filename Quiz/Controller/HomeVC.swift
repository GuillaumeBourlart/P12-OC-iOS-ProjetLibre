//
//  AppLobby.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 22/05/2023.
//

import Foundation
import UIKit

class HomeVC: UIViewController{
    
    @IBOutlet var buttons: [UIButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the navigation bar transparent (only needed in root page of controller)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "button2")]
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.playSound(soundName: "appMusic", fileType: "mp3")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        for button in buttons {
               button.isEnabled = true
               button.transform = .identity
               button.alpha = 1
           }
        
    }
    
    @IBAction func unwindToHomeVC(segue: UIStoryboardSegue) {
        
    }
   
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QuizzGroupsVC {
            destination.isQuizList = true
        }
        
        if let button = sender as? UIButton {
                button.isEnabled = false
                
            CustomAnimations.buttonPressAnimation(for: sender as! UIButton) {
                for button in self.buttons {
                    button.isEnabled = false
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        // Déplace le bouton vers la gauche en soustrayant la largeur de la vue du bouton
                        button.transform = CGAffineTransform(translationX: -self.view.frame.width, y: 0)
                        button.alpha = 0
                    })
                    
                }
                
                
            }
        }
    }
    
}

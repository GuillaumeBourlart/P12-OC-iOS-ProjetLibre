//
//  JoinWithCodeVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 28/05/2023.
//

import Foundation
import UIKit

// Class to join a room from a code
class JoinWithCodeVC: UIViewController {
    // Outlets
    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var joinButton: UIButton!
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Method called when view will appear
    override func viewWillAppear(_ animated: Bool) {
        self.joinButton.isEnabled = true
        
    }
    // Action method when the join button is pressed
    @IBAction func joinButtonPressed(sender: UIButton){
        CustomAnimations.buttonPressAnimation(for: sender) {
            
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            
            self.joinButton.isEnabled = false
            guard let code: String = self.codeField.text, !code.isEmpty else { print("error"); self.joinButton.isEnabled = true; return }
            Game.shared.joinWithCode(code: code) { result in
                switch result {
                case .failure(let error): print(error)
                    self.joinButton.isEnabled = true
                case .success(let lobbyID): self.performSegue(withIdentifier: "goToPrivateLobby", sender: lobbyID)
                }
            }
        }
        
    }
    // Called before segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PrivateLobbyVC{
            destination.lobbyId = sender as? String
            destination.isCreator = false
        }
    }
    // Action method to dismiss the keyboard when tapping outside the text field
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        codeField.resignFirstResponder()
    }
    
}

extension JoinWithCodeVC: UITextFieldDelegate {
    // Dismiss when user tap "return"
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        codeField.resignFirstResponder()
        return true
    }
}

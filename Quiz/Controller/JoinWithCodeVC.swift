//
//  JoinWithCodeVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 28/05/2023.
//

import Foundation
import UIKit

class JoinWithCodeVC: UIViewController {
    
    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var joinButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.joinButton.isEnabled = true
    }
    
    @IBAction func joinButtonPressed(sender: UIButton){
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 6.0,
                       options: [.allowUserInteraction],
                       animations: {
           sender.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                       }) { _ in
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           usingSpringWithDamping: 0.2,
                           initialSpringVelocity: 6.0,
                           options: [.allowUserInteraction],
                           animations: {
                sender.transform = CGAffineTransform.identity
            }) { _ in
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PrivateLobbyVC{
            destination.lobbyId = sender as? String
            destination.isCreator = false
        }
    }
    
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        codeField.resignFirstResponder()
    }
    
}

extension JoinWithCodeVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        codeField.resignFirstResponder()
        return true
    }
}

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
    
    @IBAction func joinButtonPressed(sender: UIButton){
        guard let code: String = self.codeField.text, !code.isEmpty else { print("error"); return }
        Game.shared.joinWithCode(code: code){result in
            switch result {
            case .failure(let error): print(error)
            case .success(let lobbyID): self.performSegue(withIdentifier: "goToPrivateLobby", sender: lobbyID)
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

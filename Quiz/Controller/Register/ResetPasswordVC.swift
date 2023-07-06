//
//  ResetPasswordVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 06/07/2023.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

class ResetPasswordVC: UIViewController {
    
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var emailField: CustomTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        guard let email = emailField.text else {return}
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Erreur lors de l'envoi de l'email de réinitialisation : \(error.localizedDescription)")
                self.errorLabel.isHidden = false
                self.errorLabel.textColor = .red
                self.errorLabel.text = "Erreur lors de l'envoi de l'email de réinitialisation"
            } else {
                print("Email de réinitialisation de mot de passe envoyé.")
                self.errorLabel.isHidden = false
                self.errorLabel.textColor = .green
                self.errorLabel.text = "Email de réinitialisation de mot de passe envoyé."
            }
        }
    }
    
    
}

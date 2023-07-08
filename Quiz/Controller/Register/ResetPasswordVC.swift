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
    
    var resetButtonTimer: Timer?
    var resetButtonSeconds: Int = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Charger le texte sauvegardé
        emailField.text = UserDefaults.standard.string(forKey: "emailFieldText")
        
        emailField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        
        // Calculer le temps restant basé sur l'heure de dernier clic
        if let lastResetTime = UserDefaults.standard.object(forKey: "lastResetTime") as? Date {
            let timePassed = Int(Date().timeIntervalSince(lastResetTime))
            if timePassed < resetButtonSeconds {
                resetButtonSeconds -= timePassed
                resetButton.isEnabled = false
                resetButton.setTitle("Please wait \(resetButtonSeconds) seconds", for: .disabled)
                resetButtonTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateResetButtonTitle(_:)), userInfo: nil, repeats: true)
            }
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let email = emailField.text, isValidEmail(email) {
            
            textField.borderStyle = .line
            textField.layer.borderColor = UIColor.green.cgColor
            textField.layer.borderWidth = 1
        } else {
            textField.layer.borderColor = UIColor.red.cgColor
            textField.layer.borderWidth = 1
            errorLabel.text = "Please, enter a valid email adress."
        }
        // Sauvegarder le texte chaque fois qu'il change
        UserDefaults.standard.set(textField.text, forKey: "emailFieldText")
    }
    
    
    @IBAction @objc func resetButtonTapped(_ sender: Any) {
        guard let email = emailField.text, isValidEmail(email) else {
            return
        }
        resetButton.isEnabled = false
        resetButton.setTitle("Please wait \(resetButtonSeconds) seconds", for: .disabled)
        
        // Démarrer le Timer
        resetButtonTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateResetButtonTitle(_:)), userInfo: nil, repeats: true)
        
        // Sauvegarder l'heure du dernier clic
        UserDefaults.standard.set(Date(), forKey: "lastResetTime")
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print(error.localizedDescription)
            }
            self.errorLabel.isHidden = false
            self.errorLabel.textColor = .green
            self.errorLabel.text = "If this email address is associated with an account, we will send you a password reset email."
            
        }
        
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    @objc func updateResetButtonTitle(_ timer: Timer) {
        resetButtonSeconds -= 1
        if resetButtonSeconds <= 0 {
            resetButton.isEnabled = true
            resetButton.setTitle("Reset Password", for: .normal)
            resetButtonTimer?.invalidate()
            resetButtonTimer = nil
            resetButtonSeconds = 60
        } else {
            resetButton.setTitle("Please wait \(resetButtonSeconds) seconds", for: .disabled)
        }
    }
    
    
}

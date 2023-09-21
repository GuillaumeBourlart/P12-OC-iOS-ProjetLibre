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

// Controller to reset the password
class ResetPasswordVC: UIViewController {
    
    // Outlets
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var emailField: CustomTextField!
    // Properties
    var resetButtonTimer: Timer? // timer
    var resetButtonSeconds: Int = 60 // default value for timer
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load saved text
        emailField.text = UserDefaults.standard.string(forKey: "emailFieldText")
        emailField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        
        // Calculate remaining time base on lat clic time
        if let lastResetTime = UserDefaults.standard.object(forKey: "lastResetTime") as? Date {
            let timePassed = Int(Date().timeIntervalSince(lastResetTime))
            if timePassed < resetButtonSeconds {
                resetButtonSeconds -= timePassed
                resetButton.isEnabled = false
                let string1 = NSLocalizedString("Please wait", comment: "")
                let string2 = NSLocalizedString("seconds", comment: "")
                resetButton.setTitle(string1 + " \(resetButtonSeconds) " + string2, for: .disabled)
                resetButtonTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateResetButtonTitle(_:)), userInfo: nil, repeats: true)
            }
        }
    }
    
    // Called each time the text in textField change
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let email = emailField.text, isValidEmail(email) {
            textField.borderStyle = .line
            textField.layer.borderColor = UIColor.green.cgColor
            textField.layer.borderWidth = 1
        } else {
            textField.layer.borderColor = UIColor.red.cgColor
            textField.layer.borderWidth = 1
            errorLabel.text = NSLocalizedString("Please, enter a valid email adress.", comment: "")
        }
        // Save the current text
        UserDefaults.standard.set(textField.text, forKey: "emailFieldText")
    }
    
    // try to send reset email when user push the reset button
    @IBAction @objc func resetButtonTapped(_ sender: Any) {
        guard let email = emailField.text, isValidEmail(email) else {
            return
        }
        resetButton.isEnabled = false
        let string1 = NSLocalizedString("Please wait", comment: "")
        let string2 = NSLocalizedString("seconds", comment: "")
        resetButton.setTitle(string1 + " \(resetButtonSeconds) " + string2, for: .disabled)
        
        // Start the timer
        resetButtonTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateResetButtonTitle(_:)), userInfo: nil, repeats: true)
        // Save time of last clic
        UserDefaults.standard.set(Date(), forKey: "lastResetTime")
        // Send the mail
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print(error.localizedDescription)
            }
            self.errorLabel.isHidden = false
            self.errorLabel.textColor = .green
            self.errorLabel.text = NSLocalizedString("If this email address is associated with an account, we will send you a password reset email.", comment: "")
            
        }
        
    }
    // Check if email is valid
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    // refresh button title
    @objc func updateResetButtonTitle(_ timer: Timer) {
        resetButtonSeconds -= 1
        if resetButtonSeconds <= 0 {
            resetButton.isEnabled = true
            let title = NSLocalizedString("Reset password", comment: "")
            resetButton.setTitle(title, for: .normal)
            resetButtonTimer?.invalidate()
            resetButtonTimer = nil
            resetButtonSeconds = 60
        } else {
            let string1 = NSLocalizedString("Please wait", comment: "")
            let string2 = NSLocalizedString("seconds", comment: "")
            resetButton.setTitle(string1 + " \(resetButtonSeconds) " + string2, for: .disabled)
        }
    }
    
    
}

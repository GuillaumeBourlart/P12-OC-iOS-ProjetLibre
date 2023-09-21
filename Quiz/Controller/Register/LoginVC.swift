//
//  LoginVC.swift
//  Quizz Culture générale
//
//  Created by Guillaume Bourlart on 20/04/2023.
//

import Foundation
import UIKit
import FirebaseAuth

// Controller for login
class LoginVC: UIViewController{
    
    //Outlets
    @IBOutlet private weak var userEmail: CustomTextField!
    @IBOutlet private weak var userPassword: CustomTextField!
    @IBOutlet weak var loginButton: CustomButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var resetPasswordButton: UILabel!
    @IBOutlet weak var backgroundForIndicator: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Method called when view will appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUI()
        tryToGetUser()
        self.loginButton.isEnabled = true
        
        // Add tap gesture to UIlabel reset password
        let tap = UITapGestureRecognizer(target: self, action: #selector(resetPasswordTapped))
        resetPasswordButton.isUserInteractionEnabled = true
        resetPasswordButton.addGestureRecognizer(tap)
    }
    
    // check if user is already connected
    func tryToGetUser() {
        FirebaseUser.shared.getUserInfo { result in
            switch result {
            case .failure(let error): print(error)
                self.backgroundForIndicator.isHidden = true
                self.indicator.stopAnimating()
            case .success(): self.performSegue(withIdentifier: "goToMenu", sender: self)
            }
        }
        
    }
    
    // called when user push "reset password" label
    @objc func resetPasswordTapped() {
        performSegue(withIdentifier: "goToResetPassword", sender: self)
    }
    
    // Try to log user when he pushed "log in" button
    @IBAction func loginUser(_ sender: UIButton) {
        CustomAnimations.buttonPressAnimation(for: self.loginButton) {
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSound(soundName: "button", fileType: "mp3")
            }
            self.loginButton.isEnabled = false
            guard let email = self.userEmail.text,
                  email != "",
                  let password = self.userPassword.text,
                  password != "" else {
                self.loginButton.isEnabled = true
                
                // handle errors
                if self.userEmail.text == "" {
                    self.userEmail.layer.borderColor = UIColor.red.cgColor
                    self.errorLabel.isHidden = false
                    self.errorLabel.text = NSLocalizedString("Email", comment: "")
                } else if self.userPassword.text == "" {
                    self.userPassword.layer.borderColor = UIColor.red.cgColor
                    self.errorLabel.isHidden = false
                    self.errorLabel.text = NSLocalizedString("Password", comment: "")
                }
                
                return
            }
            
            FirebaseUser.shared.signInUser(email: email, password: password) { result in
                switch result {
                case .success():
                    self.performSegue(withIdentifier: "goToMenu", sender: self)
                case .failure(let error):
                    print("Error logging in user: \(error.localizedDescription)")
                    self.userEmail.layer.borderColor = UIColor.red.cgColor
                    self.userPassword.layer.borderColor = UIColor.red.cgColor
                    self.errorLabel.isHidden = false
                    self.errorLabel.text = NSLocalizedString("The e-mail/password combination is incorrect.", comment: "")
                    self.loginButton.isEnabled = true
                }
            }
        }
    }
    
    // Set the page design
    func setUI(){
        // Reset UI
        self.errorLabel.isHidden = true
        userEmail.layer.borderWidth = 0.0
        userPassword.layer.borderWidth = 0.0
        
        // MAIL
        let mail = NSLocalizedString("Email", comment: "")
        userEmail.setup(image: UIImage(systemName: "mail"), placeholder: mail, placeholderColor: UIColor(named: "placeholder") ?? .gray)
        
        // PASSWORD
        let lock = NSLocalizedString("Password", comment: "")
        userPassword.setup(image: UIImage(systemName: "lock"), placeholder: lock, placeholderColor: UIColor(named: "placeholder") ?? .gray)
    }
    
    // handle keyboard dismissing
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        userEmail.resignFirstResponder()
        userPassword.resignFirstResponder()
    }
    
    // Unwind segue action method
    @IBAction func unwindToLogin(_ unwindSegue: UIStoryboardSegue) {
    }
}

extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        userEmail.resignFirstResponder()
        userPassword.resignFirstResponder()
        return true
    }
}

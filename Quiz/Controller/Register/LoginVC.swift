//
//  LoginVC.swift
//  Quizz Culture générale
//
//  Created by Guillaume Bourlart on 20/04/2023.
//

import Foundation
import UIKit
import FirebaseAuth

class LoginVC: UIViewController{
    
    @IBOutlet private weak var userEmail: CustomTextField!
    @IBOutlet private weak var userPassword: CustomTextField!
    @IBOutlet weak var loginButton: CustomButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var resetPasswordButton: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
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
                case .success(): self.performSegue(withIdentifier: "goToMenu", sender: self)
                }
            }
        
    }
    
    // Fonction appelée lorsque l'utilisateur appuie sur le label
        @objc func resetPasswordTapped() {
            performSegue(withIdentifier: "goToResetPassword", sender: self)
        }
    
    // Func to try to log user
    @IBAction func loginUser(_ sender: UIButton) {
        CustomAnimations.buttonPressAnimation(for: self.loginButton) {
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
                    self.errorLabel.text = "Please, enter an email"
                } else if self.userPassword.text == "" {
                    self.userPassword.layer.borderColor = UIColor.red.cgColor
                    self.errorLabel.isHidden = false
                    self.errorLabel.text = "Please, enter a password"
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
                    self.errorLabel.text = "The e-mail/password combination is incorrect."
                    self.loginButton.isEnabled = true
                }
            }
        }
    }
    
    // Func that handle keyboard
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        userEmail.resignFirstResponder()
        userPassword.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToMenu" {
            let tabBarController = segue.destination as! UITabBarController
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.mainTabBarController = tabBarController
        }
    }
    
    @IBAction func unwindToLogin(_ unwindSegue: UIStoryboardSegue) {
        // Vous pouvez utiliser cette méthode pour nettoyer toute donnée si nécessaire
    }
    
    
    
    
    
    func setUI(){
        // Reset UI
        self.errorLabel.isHidden = true
        userEmail.layer.borderWidth = 0.0
        userPassword.layer.borderWidth = 0.0
        
        // MAIL
        userEmail.setup(image: UIImage(systemName: "mail"), placeholder: "Mail", placeholderColor: UIColor(named: "placeholder") ?? .gray)
        
        // PASSWORD
        userPassword.setup(image: UIImage(systemName: "lock"), placeholder: "Password", placeholderColor: UIColor(named: "placeholder") ?? .gray)
    }
    
    
    
}
extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        userEmail.resignFirstResponder()
        userPassword.resignFirstResponder()
        return true
    }
    
    
}

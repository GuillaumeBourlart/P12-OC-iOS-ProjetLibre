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
    
    @IBOutlet private weak var userEmail: UITextField!
    @IBOutlet private weak var userPassword: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            FirebaseUser.shared.getUserInfo { result in
                switch result {
                case .failure(let error): print(error)
                case .success(): self.performSegue(withIdentifier: "goToMenu", sender: self)
                }
            }
            
        }
    }
    
    @IBAction func loginUser(_ sender: UIButton) {
        guard let email = userEmail.text,
              email != "",
              let password = userPassword.text,
              password != "" else {
            return
        }
        
        FirebaseUser.shared.signInUser(email: email, password: password) { result in
            switch result {
            case .success():self.performSegue(withIdentifier: "goToMenu", sender: self)
            case .failure(let error):print("Error logging in user: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        userEmail.resignFirstResponder()
        userPassword.resignFirstResponder()
    }
    
    @IBAction func unwindToLogin(_ unwindSegue: UIStoryboardSegue) {
        // Vous pouvez utiliser cette méthode pour nettoyer toute donnée si nécessaire
    }
    
    
}

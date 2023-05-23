//
//  LoginVC.swift
//  Quizz Culture générale
//
//  Created by Guillaume Bourlart on 20/04/2023.
//

import Foundation
import UIKit

class LoginVC: UIViewController{
    
    @IBOutlet private weak var userEmail: UITextField!
    @IBOutlet private weak var userPassword: UITextField!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginUser(_ sender: UIButton) {
        guard let email = userEmail.text, let password = userPassword.text else {
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
    
    
}

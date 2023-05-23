//
//  SignupVC.swift
//  Quizz Culture générale
//
//  Created by Guillaume Bourlart on 20/04/2023.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class CreateAccountVC: UIViewController {
    
    @IBOutlet private weak var userFirstname: UITextField!
    @IBOutlet private weak var userLastname: UITextField!
    @IBOutlet private weak var userPseudo: UITextField!
    @IBOutlet  weak var userDateOfBirth: UIDatePicker!
    @IBOutlet private weak var userPassword: UITextField!
    @IBOutlet private weak var userEmail: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func signUpUser(_ sender: Any) {
        guard let email = userEmail.text,
              let password = userPassword.text,
              let pseudo = userPseudo.text,
              let firstname = userFirstname.text,
              let lastname = userLastname.text else {
            return
        }
        
        FirebaseUser.shared.createUser(email: email, password: password, pseudo: pseudo, firstName: firstname, lastName: lastname, birthDate: userDateOfBirth.date) { _, error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
            } else {
                self.dismiss(animated: true)
            }
        }
    }
    
    
    
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        userEmail.resignFirstResponder()
        userPseudo.resignFirstResponder()
        userLastname.resignFirstResponder()
        userFirstname.resignFirstResponder()
        userPassword.resignFirstResponder()
        userDateOfBirth.resignFirstResponder()
    }
    
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

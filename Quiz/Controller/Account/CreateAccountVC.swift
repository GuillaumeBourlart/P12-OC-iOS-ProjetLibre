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
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardAppear(_:)), name: UIViewController.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDisappear(_:)), name: UIViewController.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tryToGetUser()
    }
    
    // check if user is already connected
    func tryToGetUser(){
        if Auth.auth().currentUser != nil {
            FirebaseUser.shared.getUserInfo { result in
                switch result {
                case .failure(let error): print(error)
                case .success(): self.performSegue(withIdentifier: "goToMenu", sender: self)
                }
            }
        }
    }
    
    // try to sign up user
    @IBAction func signUpUser(_ sender: Any) {
        guard let email = userEmail.text,
              email != "",
              let password = userPassword.text,
              password != "",
              let pseudo = userPseudo.text,
              pseudo != "",
              let firstname = userFirstname.text,
              firstname != "",
              let lastname = userLastname.text,
              lastname != "" else {
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
    
    
    // Handle keyboard dismissing
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
extension CreateAccountVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        userEmail.resignFirstResponder()
        userPseudo.resignFirstResponder()
        userLastname.resignFirstResponder()
        userFirstname.resignFirstResponder()
        userPassword.resignFirstResponder()
        userDateOfBirth.resignFirstResponder()
        return true
    }
    
    @objc func keyboardAppear(_ notification: Notification) {
            guard let frame = notification.userInfo?[UIViewController.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            let keyboardFrame = frame.cgRectValue
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardFrame.height
            }
        }

    @objc func keyboardDisappear(_ notification: Notification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}

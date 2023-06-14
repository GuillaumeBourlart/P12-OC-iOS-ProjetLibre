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
    
    @IBOutlet private weak var userPseudo: UITextField!
    @IBOutlet  weak var userDateOfBirth: UIDatePicker!
    @IBOutlet private weak var userPassword: UITextField!
    @IBOutlet private weak var userEmail: UITextField!
    @IBOutlet weak var signinButton: CustomButton!
    
    var activeTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardAppear(_:)), name: UIViewController.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDisappear(_:)), name: UIViewController.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tryToGetUser()
        self.signinButton.isEnabled = true
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
        CustomAnimations.buttonPressAnimation(for: self.signinButton) {
            self.signinButton.isEnabled = false
            guard let email = self.userEmail.text,
                  email != "",
                  let password = self.userPassword.text,
                  password != "",
                  let pseudo = self.userPseudo.text,
                  pseudo != "" else {
                self.signinButton.isEnabled = true
                return
            }
            
            FirebaseUser.shared.createUser(email: email, password: password, pseudo: pseudo, birthDate: self.userDateOfBirth.date) { _, error in
                if let error = error {
                    print("Error creating user: \(error.localizedDescription)")
                    self.signinButton.isEnabled = true
                } else {
                    self.dismiss(animated: true)
                    
                }
            }
        }
        
    }
    
    
    // Handle keyboard dismissing
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        userEmail.resignFirstResponder()
        userPseudo.resignFirstResponder()
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
        userPassword.resignFirstResponder()
        userDateOfBirth.resignFirstResponder()
        return true
    }
    
    @objc func keyboardAppear(_ notification: Notification) {
           guard let frame = notification.userInfo?[UIViewController.keyboardFrameEndUserInfoKey] as? NSValue else { return }
           let keyboardFrame = frame.cgRectValue
           guard let activeTextField = activeTextField else { return }
           let activeTextFieldFrame = activeTextField.convert(activeTextField.bounds, to: self.view)
           
           if self.view.frame.origin.y == 0 && activeTextFieldFrame.maxY > keyboardFrame.origin.y {
               self.view.frame.origin.y -= activeTextFieldFrame.maxY - keyboardFrame.origin.y + 20 // +20 for a little extra space
           }
       }
       
       @objc func keyboardDisappear(_ notification: Notification) {
           if self.view.frame.origin.y != 0 {
               self.view.frame.origin.y = 0
           }
       }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
}

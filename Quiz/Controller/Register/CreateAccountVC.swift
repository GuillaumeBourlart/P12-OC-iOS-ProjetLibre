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
    
    @IBOutlet private weak var userPseudo: CustomTextField!
    @IBOutlet private weak var userPassword: CustomTextField!
    @IBOutlet private weak var userEmail: CustomTextField!
    @IBOutlet weak var signinButton: CustomButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    var activeTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardAppear(_:)), name: UIViewController.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDisappear(_:)), name: UIViewController.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUI()
        tryToGetUser()
        self.signinButton.isEnabled = true
    }
    
    // check if user is already connected
    func tryToGetUser(){
            FirebaseUser.shared.getUserInfo { result in
                switch result {
                case .failure(let error): print(error)
                case .success(): self.performSegue(withIdentifier: "goToMenu", sender: self)
                }
            }
    }
    
    // try to sign up user
    @IBAction func signUpUser(_ sender: Any) {
        CustomAnimations.buttonPressAnimation(for: self.signinButton) {
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSound(soundName: "button", fileType: "mp3")
            }
            self.signinButton.isEnabled = false
            guard let email = self.userEmail.text, !email.isEmpty,
                  let password = self.userPassword.text, !password.isEmpty,
                  let pseudo = self.userPseudo.text, !pseudo.isEmpty else {
                // Update UI for empty fields error
                self.updateUIForError("All fields are required!", textField: nil)
                return
            }
            
            FirebaseUser.shared.createUser(email: email, password: password, pseudo: pseudo) { result in
                switch result {
                case .failure(let error):
                    print("Error creating user: \(error.localizedDescription)")
                    // Update UI for creation error
                    self.updateUIForError(error.localizedDescription, textField: nil)
                case .success():
                    
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    func updateUIForError(_ error: String, textField: UITextField?) {
        self.errorLabel.text = error
        self.errorLabel.isHidden = false
        self.signinButton.isEnabled = true
        
        if let textField = textField {
            textField.layer.borderColor = UIColor.red.cgColor
            textField.layer.borderWidth = 1.0
        }
    }
    
    func setUI(){
        
        // Reset UI
        self.errorLabel.isHidden = true
        userEmail.layer.borderWidth = 0.0
        userPassword.layer.borderWidth = 0.0
        userPseudo.layer.borderWidth = 0.0
        
        // MAIL
        let mail = NSLocalizedString("Mail", comment: "")
        userEmail.setup(image: UIImage(systemName: "mail"), placeholder: mail, placeholderColor: UIColor(named: "placeholder") ?? UIColor.gray)

        // PASSWORD
        let password = NSLocalizedString("Password", comment: "")
        userPassword.setup(image: UIImage(systemName: "lock"), placeholder: password, placeholderColor: UIColor(named: "placeholder") ?? UIColor.gray)

        // USERNAME
        let username = NSLocalizedString("Username", comment: "")
        userPseudo.setup(image: UIImage(systemName: "person.fill"), placeholder: username, placeholderColor: UIColor(named: "placeholder") ?? UIColor.gray)
    }
    
    
    // Handle keyboard dismissing
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        userEmail.resignFirstResponder()
        userPseudo.resignFirstResponder()
        userPassword.resignFirstResponder()
    }
    
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}


// Handle keyboard
extension CreateAccountVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        userEmail.resignFirstResponder()
        userPseudo.resignFirstResponder()
        userPassword.resignFirstResponder()
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

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
    @IBOutlet private weak var userPassword: UITextField!
    @IBOutlet private weak var userEmail: UITextField!
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
                guard let email = self.userEmail.text, !email.isEmpty,
                    let password = self.userPassword.text, !password.isEmpty,
                    let pseudo = self.userPseudo.text, !pseudo.isEmpty else {
                        // Update UI for empty fields error
                        self.updateUIForError("All fields are required!", textField: nil)
                        return
                }

                FirebaseUser.shared.createUser(email: email, password: password, pseudo: pseudo) { _, error in
                    if let error = error {
                        print("Error creating user: \(error.localizedDescription)")
                        // Update UI for creation error
                        self.updateUIForError(error.localizedDescription, textField: nil)
                    } else {
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
        
        userEmail.layer.cornerRadius = userEmail.frame.height / 2
        userEmail.clipsToBounds = true
        var imageView = UIImageView(image: UIImage(systemName: "mail"))
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
        
        // Définition du placeholder en gris clair
        let attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: "placeholder")])
        userEmail.attributedPlaceholder = attributedPlaceholder
        
        var view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20)) // Augmentez la largeur de la vue
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20) // Centrez l'image dans la vue
        
        view.addSubview(imageView)
        
        userEmail.leftViewMode = .always
        userEmail.leftView = view
        
        // PASSWORD
        
        userPassword.layer.cornerRadius = userPassword.frame.height / 2
        userPassword.clipsToBounds = true
        
        imageView = UIImageView(image: UIImage(systemName: "lock"))
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
        
        // Définition du placeholder en gris clair
        let attributedPlaceholder2 = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: "placeholder")])
        userPassword.attributedPlaceholder = attributedPlaceholder2
        
        view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20)) // Augmentez la largeur de la vue
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20) // Centrez l'image dans la vue
        
        view.addSubview(imageView)
        userPassword.leftViewMode = .always
        userPassword.leftView = view
        
        // USERNAME
        
        userPseudo.layer.cornerRadius = userPseudo.frame.height / 2
        userPseudo.clipsToBounds = true
        
        imageView = UIImageView(image: UIImage(systemName: "person.fill"))
        imageView.tintColor = UIColor.white
        imageView.contentMode = .scaleAspectFit
       
        // Définition du placeholder en gris clair
        let attributedPlaceholder3 = NSAttributedString(string: "Pseudo", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        userPseudo.attributedPlaceholder = attributedPlaceholder3
        
        view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20)) // Augmentez la largeur de la vue
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20) // Centrez l'image dans la vue
        
        view.addSubview(imageView)
        userPseudo.leftViewMode = .always
        userPseudo.leftView = view
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

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
    @IBOutlet weak var loginButton: CustomButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUI()
        tryToGetUser()
        self.loginButton.isEnabled = true
        
    }
    // check if user is already connected
    func tryToGetUser() {
        if Auth.auth().currentUser != nil {
            FirebaseUser.shared.getUserInfo { result in
                switch result {
                case .failure(let error): print(error)
                case .success(): self.performSegue(withIdentifier: "goToMenu", sender: self)
                }
            }
            
        }
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
                            
                            // Gestion des erreurs avec une bordure rouge et des labels d'erreur
                            if self.userEmail.text == "" {
                                self.userEmail.layer.borderColor = UIColor.red.cgColor
                                self.errorLabel.isHidden = false
                                self.errorLabel.text = "Veuillez entrer votre e-mail."
                            } else if self.userPassword.text == "" {
                                self.userPassword.layer.borderColor = UIColor.red.cgColor
                                self.errorLabel.isHidden = false
                                self.errorLabel.text = "Veuillez entrer votre mot de passe."
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
                                self.errorLabel.text = "La combinaison e-mail/mot de passe est incorrecte."
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
            // Maintenant, vous avez l'instance du UITabBarController qui va être présenté
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
        userEmail.layer.cornerRadius = userEmail.frame.height / 2
        userEmail.clipsToBounds = true
        
        var imageView = UIImageView(image: UIImage(systemName: "mail"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor  = UIColor.white
        
        
        
        // Définition du placeholder en gris clair
        let attributedPlaceholder = NSAttributedString(string: "Mail", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: "placeholder")])
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
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor  = UIColor.white
        
        
        
        // Définition du placeholder en gris clair
        let attributedPlaceholder2 = NSAttributedString(string: "Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: "placeholder")])
        userPassword.attributedPlaceholder = attributedPlaceholder2
        
        view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20)) // Augmentez la largeur de la vue
        imageView.frame = CGRect(x: 10, y: 0, width: 20, height: 20) // Centrez l'image dans la vue
        
        view.addSubview(imageView)
        userPassword.leftViewMode = .always
        userPassword.leftView = view
    }
    
    
    
}
extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        userEmail.resignFirstResponder()
        userPassword.resignFirstResponder()
        return true
    }
    
    
}

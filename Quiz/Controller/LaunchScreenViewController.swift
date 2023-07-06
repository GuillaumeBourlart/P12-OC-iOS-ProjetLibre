//
//  LaunchScreenViewController.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 06/07/2023.
//

import Foundation
import UIKit
import FirebaseAuth

class LaunchScreenViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if user is already logged in
        if Auth.auth().currentUser != nil {
            FirebaseUser.shared.getUserInfo { result in
                switch result {
                case .failure(let error):
                    print(error)
                    self.presentLoginScreen()
                case .success():
                    self.presentTabBar()
                }
            }
        } else {
            self.presentLoginScreen()
        }
    }
    
    func presentLoginScreen() {
        DispatchQueue.main.async {
            // Assuming you have a storyboard named "Main" and
            // your login view controller is identified by "LoginVC"
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC")
            loginVC.modalPresentationStyle = .fullScreen
            self.present(loginVC, animated: true, completion: nil)
        }
    }
    
    func presentTabBar() {
        DispatchQueue.main.async {
            // Assuming your Tab Bar is identified by "TabBarController"
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController")
            tabBarController.modalPresentationStyle = .fullScreen
            self.present(tabBarController, animated: true, completion: nil)
        }
    }
}

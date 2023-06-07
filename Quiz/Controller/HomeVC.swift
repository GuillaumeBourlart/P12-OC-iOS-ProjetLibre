//
//  AppLobby.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 22/05/2023.
//

import Foundation
import UIKit

class HomeVC: UIViewController{
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the navigation bar transparent (only needed in root page of controller)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "button2")]
        
    }
    
    @IBAction func unwindToHomeVC(segue: UIStoryboardSegue) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QuizzGroupsVC {
            destination.isQuizList = true
        }
    }
    
}

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
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        
    }
    
    @IBAction func unwindToHomeVC(segue: UIStoryboardSegue) {
        
    }
    
    
}

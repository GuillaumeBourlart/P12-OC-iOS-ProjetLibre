//
//  LanguageViewController.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 16/06/2023.
//

import Foundation
import UIKit

class LanguageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let languages = ["EN", "ES", "FR", "DE", "JA", "IT", "KO", "ZH", "RU", "PT"]
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedLanguage = UserDefaults.standard.string(forKey: "SelectedLanguage") {
            // Find the index of the selected language
            if let selectedIndex = languages.firstIndex(of: selectedLanguage) {
                // Create an IndexPath and select the row in the table view
                let indexPath = IndexPath(row: selectedIndex, section: 0)
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
    }
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath) as! LanguageCell
        cell.languageLabel.text = languages[indexPath.row]
        cell.languageLabel.textColor = .white // Set the text color to white
        // Set the image for the flag. For this example, the image assets are named the same as the language name.
        cell.flagImageView.image = UIImage(named: languages[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLanguage = languages[indexPath.row]
        // Store the selected language
        UserDefaults.standard.set(selectedLanguage, forKey: "SelectedLanguage")
    }
}

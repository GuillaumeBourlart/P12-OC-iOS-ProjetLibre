//
//  HistoryVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 13/05/2023.
//

import Foundation
import UIKit

// Class to display histoiry of competitive and normal games
class HistoryVC: UIViewController {
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var gameModeControl: UISegmentedControl!
    // Properties
    // Store every user's games
    var games: [GameData] {
        let allGames = FirebaseUser.shared.History ?? []
        switch gameModeControl.selectedSegmentIndex {
        case 0: // competitive games
            return allGames.filter { $0.competitive }
        case 1: // non-competitive games
            return allGames.filter { !$0.competitive }
        default:
            return allGames
        }
    }
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        // get all completed games of user
        Game.shared.getCompletedGames { result in
            switch result {
            case .success(): self.tableView.reloadData()
            case .failure(let error): print(error)
            }
        }
    }
    
    // reload data depending of the selected segmented control index
    @IBAction func gameModeChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
    
    // Called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ResultVC{
            destination.gameData = sender as? GameData
        }
    }
}


extension HistoryVC: UITableViewDelegate, UITableViewDataSource {
    
    // Set the height for each row in the table view
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    // Define the number of rows in the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.games.count
    }
    
    // Configure and return a cell for a specific row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as? CustomCell else { return UITableViewCell() }
        
        // Create a date formatter to format the date from the game
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let date = self.games[indexPath.row].date
        let dateString = formatter.string(from: date)
        
        // Add disclosure indicator to the cell
        cell.accessoryType = .disclosureIndicator
        cell.label.text = dateString
        
        return cell
    }
    
    // Handle row selection in the table view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedGame = games[indexPath.row]
        performSegue(withIdentifier: "goToResult", sender: selectedGame)
    }
}

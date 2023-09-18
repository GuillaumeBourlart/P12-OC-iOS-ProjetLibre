//
//  HistoryVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 13/05/2023.
//

import Foundation
import UIKit

class HistoryVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var gameModeControl: UISegmentedControl!
    
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
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ResultVC{
            destination.gameData = sender as? GameData
        }
    }
}


extension HistoryVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 70.0
        }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.games.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as? CustomCell else {return UITableViewCell()}
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let date = self.games[indexPath.row].date
        let dateString = formatter.string(from: date)
        
        let whiteDisclosureIndicator = UIImageView(image: UIImage(named: "whiteCustomDisclosureIndicator"))
        whiteDisclosureIndicator.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        cell.accessoryView = whiteDisclosureIndicator
        cell.label.text = dateString
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
            let selectedGame = games[indexPath.row]
        performSegue(withIdentifier: "goToResult", sender: selectedGame)
    }
    
}

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Game.shared.getCompletedGames { result in
            switch result {
            case .success(): self.tableView.reloadData()
            case .failure(let error): print(error)
            }
        }
    }
    
    var games: [GameData] {
        return FirebaseUser.shared.History ?? []
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ResultVC{
            
            destination.gameData = sender as? GameData
        }
    }
    
    
}


extension HistoryVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.games.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as? CustomCell else {return UITableViewCell()}
        
        cell.label.text = self.games[indexPath.row].name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Désélectionnez la cellule pour une meilleure expérience utilisateur
        
            let selectedGame = games[indexPath.row]
            print("Informations du quiz sélectionné : \(selectedGame)")
        performSegue(withIdentifier: "goToResult", sender: selectedGame)
    }
    
}

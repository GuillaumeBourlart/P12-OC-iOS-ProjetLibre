//
//  QuickGame.swift
//  Quizz Culture générale
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import UIKit
import Alamofire

class QuickPlayVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var categories: [[String: Any]] = []
    
    let apiManager = OpenTriviaDatabaseManager(service: Service(networkRequest: AlamofireNetworkRequest()))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Masquer le bouton "back"
        //        self.navigationItem.hidesBackButton = true
        
        collectionView.dataSource = self
        collectionView.delegate = self
        loadCategories()
    }
    
    func loadCategories() {
        apiManager.fetchCategories { [weak self] result in
            switch result {
            case .failure(let error): print(error)
            case .success(let categories):
                self?.categories = categories
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                }
                print(categories)
            }
            
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        
        let category = categories[indexPath.row]
        cell.categoryLabel.text = category["name"] as? String
        cell.tag = (category["id"] as? Int)!
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Code à exécuter lorsque l'utilisateur touche une cellule de la collection view
        // indexPath.row contient l'index de la cellule sélectionnée
        // Récupérer la cellule à partir de l'indexPath
        let cell = collectionView.cellForItem(at: indexPath)
        
        // Accéder au tag de la cellule
        let cellTag = cell?.tag
        Game.shared.category = cellTag
        
        let alertController = UIAlertController(title: "Choisir la difficulté", message: nil, preferredStyle: .alert)
        
        let facileAction = UIAlertAction(title: "Facile", style: .default) { (action) in
            // Code à exécuter lorsque l'utilisateur choisit "Facile"
            Game.shared.difficulty = "easy"
            self.performSegue(withIdentifier: "goToOpponentsList", sender: self)
        }
        let moyenAction = UIAlertAction(title: "Moyen", style: .default) { (action) in
            // Code à exécuter lorsque l'utilisateur choisit "Moyen"
            Game.shared.difficulty = "medium"
            self.performSegue(withIdentifier: "goToOpponentsList", sender: self)
        }
        let difficileAction = UIAlertAction(title: "Difficile", style: .default) { (action) in
            // Code à exécuter lorsque l'utilisateur choisit "Difficile"
            Game.shared.difficulty = "hard"
            self.performSegue(withIdentifier: "goToOpponentsList", sender: self)
        }
        
        alertController.addAction(facileAction)
        alertController.addAction(moyenAction)
        alertController.addAction(difficileAction)
        
        // Changer la couleur de fond de l'alerte
        alertController.view.tintColor = UIColor(red: 239/255, green: 76/255, blue: 81/255, alpha: 1)
        alertController.view.backgroundColor = UIColor(red: 243/255, green: 243/255, blue: 243/255, alpha: 1)
        
        present(alertController, animated: true, completion: nil)
    }
    
}



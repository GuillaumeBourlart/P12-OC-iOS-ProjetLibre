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
    @IBOutlet weak var searchQuizField: UITextField!
    
    var categories: [[String: Any]] = []
    let apiManager = OpenTriviaDatabaseManager(service: Service(networkRequest: AlamofireNetworkRequest()))
    var difficulty: String?
    var category: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        // margins total = 40 (left) + 40 (right)
        let margins: CGFloat = 40 + 40
        // spacing between cells
        let spacing: CGFloat = 25
        // Get the screen's width
        let screenWidth = UIScreen.main.bounds.width
        // Calculate the width for each item
        let itemWidth = (screenWidth - margins - spacing) / 2

        // Set the item size
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing

        // Set the layout to the collectionView
        collectionView.collectionViewLayout = layout
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? OpponentChoice {
            destination.category = self.category
            destination.difficulty = self.difficulty
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
        cell.tag = category["id"] as? Int ?? 0
        cell.layer.cornerRadius = 10
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Code à exécuter lorsque l'utilisateur touche une cellule de la collection view
        // indexPath.row contient l'index de la cellule sélectionnée
        // Récupérer la cellule à partir de l'indexPath
        let cell = collectionView.cellForItem(at: indexPath)
        
        // Accéder au tag de la cellule
        let cellTag = cell?.tag
        self.category = cellTag
        
        let alertController = UIAlertController(title: "Choisir la difficulté", message: nil, preferredStyle: .alert)
        
        let facileAction = UIAlertAction(title: "Facile", style: .default) { (action) in
            // Code à exécuter lorsque l'utilisateur choisit "Facile"
            self.difficulty = "easy"
            self.performSegue(withIdentifier: "goToOpponentsList", sender: self)
        }
        let moyenAction = UIAlertAction(title: "Moyen", style: .default) { (action) in
            // Code à exécuter lorsque l'utilisateur choisit "Moyen"
            self.difficulty = "medium"
            self.performSegue(withIdentifier: "goToOpponentsList", sender: self)
        }
        let difficileAction = UIAlertAction(title: "Difficile", style: .default) { (action) in
            // Code à exécuter lorsque l'utilisateur choisit "Difficile"
            self.difficulty = "hard"
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



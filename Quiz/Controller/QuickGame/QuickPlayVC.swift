//
//  QuickGame.swift
//  Quizz Culture générale
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import UIKit
import Alamofire

class QuickPlayVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var categories: [[String: Any]] = []
    let apiManager = OpenTriviaDatabaseManager(service: Service(networkRequest: AlamofireNetworkRequest()))
    var difficulty: String?
    var category: Int?
    var activeAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()
        setCategoriesSize()
        
        //handle music
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.playSound(soundName: "appMusic", fileType: "mp3")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // If an alert is being displayed, dismiss it
        if let activeAlert = activeAlert {
            activeAlert.dismiss(animated: false)
            self.activeAlert = nil
        }
    }
    
    func loadCategories() {
        if let categories = OpenTriviaDatabaseManager.categories, !categories.isEmpty {
            self.categories = categories
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } else {
            activityIndicator.startAnimating()
            apiManager.fetchCategories { [weak self] result in
                switch result {
                case .failure(let error): print(error)
                case .success(let categories):
                    self?.activityIndicator.stopAnimating()
                    self?.categories = categories
                    DispatchQueue.main.async {
                        self?.collectionView.reloadData()
                    }
                    print(categories)
                }
                
            }
        }
    }
    
    func setCategoriesSize(){
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        // margins total = 40 (left) + 40 (right)
        let margins: CGFloat = 20 + 20
        // spacing between cells
        let spacing: CGFloat = 20
        // Get the screen's width
        let screenWidth = UIScreen.main.bounds.width
        // Calculate the width for each item
        let itemWidth = (screenWidth - margins - spacing) / 2
        
        // Set the item size
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth/3*2)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        // Set the layout to the collectionView
        collectionView.collectionViewLayout = layout
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
        cell.layer.cornerRadius = 20
        cell.layer.borderWidth = 2
        cell.layer.borderColor = UIColor(named: "button")?.cgColor ?? UIColor.black.cgColor
        
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        
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
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(facileAction)
        alertController.addAction(moyenAction)
        alertController.addAction(difficileAction)
        alertController.addAction(cancelAction)
        
        self.activeAlert = alertController
        
        present(alertController, animated: true, completion: nil)
    }
    
    
}



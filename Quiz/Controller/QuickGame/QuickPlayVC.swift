//
//  QuickGame.swift
//  Quizz Culture générale
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import UIKit
import Alamofire
import FirebasePerformance

// Class to chose a categories, join a room or see private quizzes
class QuickPlayVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // Outlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    // Properties
    var categories: [[String: Any]] = [] // Holds a list of trivia categories.
    let apiManager = OpenTriviaDatabaseManager(service: Service(networkRequest: AlamofireNetworkRequest()), translatorService: Service(networkRequest: AlamofireNetworkRequest())) // Manager for OpenTriviaDatabase API.
    var difficulty: String?  // Selected difficulty level.
    var category: Int?  // Selected category.
    var activeAlert: UIAlertController? // for alert displaying
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()
        setCategoriesSize()
        
        //handle music
        if let tabBar = self.tabBarController as? CustomTabBarController {
            tabBar.playSound(soundName: "appMusic", fileType: "mp3")
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.mainTabBarController = tabBar
        }
        
        // show consent for firebase performance only the first time
        if UserDefaults.standard.object(forKey: "firebasePerformanceEnabled") == nil {
            showFirebaseConsentDialog()
        }
    }
    
    // Method called when view will disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // If an alert is being displayed, dismiss it
        if let activeAlert = activeAlert {
            activeAlert.dismiss(animated: false)
            self.activeAlert = nil
        }
    }
    
    // This method displays a dialog asking for user consent to use Firebase Performance.
    func showFirebaseConsentDialog() {
        // Create an alert controller with a title and message.
        let alertController = UIAlertController(title: NSLocalizedString("Consent", comment: ""), message: NSLocalizedString("We use Firebase Performance to improve the efficiency of our application. Are you okay with leaving Firebase Performance enabled?", comment: ""), preferredStyle: .alert)
        
        // Action to take when the user agrees to enable Firebase Performance.
        let agreeAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default) { _ in
            // Store the user's preference in UserDefaults.
            UserDefaults.standard.set(true, forKey: "firebasePerformanceEnabled")
            // Enable data collection in Firebase Performance.
            Performance.sharedInstance().isDataCollectionEnabled = true
        }
        
        // Action to take when the user disagrees to enable Firebase Performance.
        let disagreeAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel) { _ in
            // Store the user's preference in UserDefaults.
            UserDefaults.standard.set(false, forKey: "firebasePerformanceEnabled")
            // Disable data collection in Firebase Performance.
            Performance.sharedInstance().isDataCollectionEnabled = false
        }
        
        // Add actions to the alert controller.
        alertController.addAction(agreeAction)
        alertController.addAction(disagreeAction)
        // Present the alert controller.
        self.present(alertController, animated: true, completion: nil)
    }
    
    // This method loads trivia categories either from a cached source or by making an API call.
    func loadCategories() {
        // If categories are already available (cached), use them.
        if let categories = OpenTriviaDatabaseManager.categories, !categories.isEmpty {
            self.categories = categories
            // Reload the collection view to display the new categories.
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } else {
            // If categories are not cached, show an activity indicator while fetching them.
            activityIndicator.startAnimating()
            // Make an API call to fetch categories.
            apiManager.fetchCategories { [weak self] result in
                switch result {
                case .failure(let error):
                    // Print the error if the API call fails.
                    print(error)
                case .success(let categories):
                    // Stop the activity indicator once data is fetched.
                    self?.activityIndicator.stopAnimating()
                    // Update the categories list.
                    self?.categories = categories
                    // Reload the collection view to display the new categories.
                    DispatchQueue.main.async {
                        self?.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    // This function sets the size of the categories within the collection view.
    func setCategoriesSize(){
        // Create a new flow layout for the collection view.
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        
        // Define the total margins for left and right.
        let margins: CGFloat = 20 + 20  // 20 each for left and right
        
        // Define the spacing between cells.
        let spacing: CGFloat = 20
        
        // Get the width of the screen.
        let screenWidth = UIScreen.main.bounds.width
        
        // Calculate the width of each item based on the screen width, margins, and spacing.
        let itemWidth = (screenWidth - margins - spacing) / 2
        
        // Set the size of the items.
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth/3*2)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        // Apply the layout to the collection view.
        collectionView.collectionViewLayout = layout
    }
    
    // This function prepares the data before transitioning to the next screen (OpponentChoice).
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? OpponentChoice {
            destination.category = self.category
            destination.difficulty = self.difficulty
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    // Define the number of items in a section.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    // Define the appearance and data of each cell.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        let category = categories[indexPath.row]
        cell.categoryLabel.text = category["name"] as? String
        cell.tag = category["id"] as? Int ?? 0
        cell.layer.cornerRadius = 20
        return cell
    }
    
    // Define what happens when a cell is selected.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        let cellTag = cell?.tag
        self.category = cellTag
        
        // Show an alert asking the user to choose a difficulty level.
        let alertController = UIAlertController(title: NSLocalizedString("Choose difficulty", comment: ""), message: nil, preferredStyle: .alert)
        
        // Define actions for each difficulty level.
        let facileAction = UIAlertAction(title: NSLocalizedString("Easy", comment: ""), style: .default) { (action) in
            self.difficulty = "easy"
            self.performSegue(withIdentifier: "goToOpponentsList", sender: self)
        }
        let moyenAction = UIAlertAction(title: NSLocalizedString("Medium", comment: ""), style: .default) { (action) in
            self.difficulty = "medium"
            self.performSegue(withIdentifier: "goToOpponentsList", sender: self)
        }
        let difficileAction = UIAlertAction(title: NSLocalizedString("Hard", comment: ""), style: .default) { (action) in
            self.difficulty = "hard"
            self.performSegue(withIdentifier: "goToOpponentsList", sender: self)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
        
        // Add actions to the alert controller.
        alertController.addAction(facileAction)
        alertController.addAction(moyenAction)
        alertController.addAction(difficileAction)
        alertController.addAction(cancelAction)
        
        self.activeAlert = alertController
        
        // Present the alert to the user.
        present(alertController, animated: true, completion: nil)
    }
    
    
    
}



//
//  ModifyGroupVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 22/06/2023.
//

import FirebaseFirestore
import Foundation
import UIKit

// Class to modify a group (members and name)
class ModifyGroupVC: UIViewController{
    
    // Outlets
    @IBOutlet weak var modifyButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addQuestionButton: UIButton!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    // properties
    var groupID: String? // current Group id
    var group: FriendGroup? { return FirebaseUser.shared.friendGroups?.first(where: { $0.id == groupID }) } // Get current group information
    var usernames = [String: String]() // store current group members usernames
    var isModifying = false // Check if user is modidying group's name
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        tapGestureRecognizer.cancelsTouchesInView = false
    }
    
    // Method called when view will appear
    override func viewWillAppear(_ animated: Bool) {
        addQuestionButton.isEnabled = true
        modifyButton.isEnabled = true
        nameField.text = group?.name
        getUsernames()
    }
    
    // get group's members names
    func getUsernames(){
        guard let group = group, group.members != [] else { self.usernames = [:]; self.tableView.reloadData(); return}
        FirebaseUser.shared.fetchGroupMembers(group: group) { result in
            switch result {
            case .failure(let error): print(error)
            case .success(let members): self.usernames = members
                self.tableView.reloadData()
            }
        }
    }
    
    // function called when modify button is pressed
    @IBAction func modifyButtonWasTapped(_ sender: UIButton) {
        self.addQuestionButton.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: sender) {
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            if self.isModifying {
                self.isModifying = false
                self.nameField.layer.borderColor = UIColor.clear.cgColor
                
                self.nameField.isUserInteractionEnabled = false
                
                self.nameField.layer.borderWidth = 0
                
                self.modifyButton.backgroundColor = UIColor.red
                self.modifyButton.setImage(UIImage(systemName: "pencil"), for: .normal)
                
                self.saveModifications()
            }else {
                self.isModifying = true
                self.nameField.layer.borderColor = UIColor.green.cgColor
                self.nameField.isUserInteractionEnabled = true
                
                self.nameField.layer.borderWidth = 1
                
                self.modifyButton.backgroundColor = UIColor.green
                self.modifyButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
            }
            
        }
    }
    
    // save name modification
    func saveModifications(){
        guard let name = nameField.text, name != "", let id = group?.id else {return}
        
        FirebaseUser.shared.updateGroupName(groupID: id, newName: name) { result in
            switch result {
            case .success():
                self.tableView.reloadData()
            case .failure(let error):
                print(error)
            }
            self.addQuestionButton.isEnabled = true
        }
        
        
    }
    
    // navifate to addMemeberVC
    @IBAction func addButtonTapped(_ sender: UIButton) {
        self.addQuestionButton.isEnabled = false
        CustomAnimations.buttonPressAnimation(for: sender) {
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            self.addQuestionButton.isEnabled = false
            self.modifyButton.isEnabled = false
            
            if self.group != nil {
                self.performSegue(withIdentifier: "goToAddMember", sender: self)
            } else {
                self.addQuestionButton.isEnabled = true
            }
        }
    }
    
    // called before the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? AddMemberVC {
            destination.group = self.group
        }
    }
    
    // dismiss the keyboard
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        nameField.resignFirstResponder()
    }
}
// UITableViewDelegate and UITableViewDataSource methods for handling table view actions
extension ModifyGroupVC: UITableViewDelegate, UITableViewDataSource {
    
    // Define the height for table view rows
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0 // Replace with the desired height
    }
    
    // Define the number of rows in the table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if group != nil {
            return usernames.count
        } else {
            return 0
        }
    }
    
    // Configure and provide cells for the table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
        
        if group != nil {
            let userId = Array(usernames.keys)[indexPath.row] // Get the user ID from the usernames dictionary keys
            let userName = usernames[userId] // Get the corresponding username
            cell.label.text = userName
        }
        
        
        
        return cell
    }
    
    // Handle row deletion when in editing mode
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let group = group {
                let memberIdToRemove = Array(usernames.keys)[indexPath.row]
                FirebaseUser.shared.removeMemberFromGroup(group: group, memberId: memberIdToRemove) { result in
                    switch result {
                    case .success():
                        self.getUsernames()
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
}

// UITextFieldDelegate method for handling text field actions
extension ModifyGroupVC: UITextFieldDelegate {
    
    // Handle the return key press in the text field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nameField.resignFirstResponder() // Dismiss the keyboard when return key is pressed
        return true
    }
}



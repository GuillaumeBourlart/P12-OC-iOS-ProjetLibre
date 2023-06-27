//
//  ModifyGroupVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 22/06/2023.
//

import Foundation

//
//  Modification.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 03/05/2023.
//
import FirebaseFirestore
import Foundation
import UIKit

class ModifyGroupVC: UIViewController{
    
    @IBOutlet weak var modifyButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addQuestionButton: UIButton!
    
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    var groupID: String?
    var group: FriendGroup? {
        return FirebaseUser.shared.friendGroups?.first(where: { $0.id == groupID })
    }
    
    var usernames = [String: String]()
    var isModifying = false
    
    override func viewDidLoad() {
        tapGestureRecognizer.cancelsTouchesInView = false
        super.viewDidLoad()
        
            nameField.text = group?.name
        
    }
        
        override func viewWillAppear(_ animated: Bool) {
            addQuestionButton.isEnabled = true
            modifyButton.isEnabled = true
            getUsernames()
        }
    
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
        
        @IBAction func modifyButtonWasTapped(_ sender: UIButton) {
            self.addQuestionButton.isEnabled = false
            CustomAnimations.buttonPressAnimation(for: sender) {
                
               
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
        
        @IBAction func addButtonTapped(_ sender: UIButton) {
            self.addQuestionButton.isEnabled = false
            CustomAnimations.buttonPressAnimation(for: sender) {
                self.addQuestionButton.isEnabled = false
                self.modifyButton.isEnabled = false
                
                 if self.group != nil {
                    self.performSegue(withIdentifier: "goToAddMember", sender: self)
                } else {
                    self.addQuestionButton.isEnabled = true
                }
            }
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            
            
            if let destination = segue.destination as? AddMemberVC {
                destination.group = self.group
            }
        }
        
        @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
            nameField.resignFirstResponder()
        }
        
        
    }
    
    extension ModifyGroupVC: UITableViewDelegate, UITableViewDataSource {
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 70.0 // Remplacer par la hauteur désirée
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if group != nil {
                return usernames.count
            }else{
                return 0
            }
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomCell
            
             if group != nil {
                let userId = Array(usernames.keys)[indexPath.row] // Récupérer l'id d'utilisateur à partir des clés du dictionnaire usernames
                let userName = usernames[userId] // Récupérer le nom d'utilisateur correspondant
                cell.label.text = userName
            }
            
            let whiteDisclosureIndicator = UIImageView(image: UIImage(named: "whiteCustomDisclosureIndicator")) // Remplacez "customDisclosureIndicator" par le nom de votre image.
            whiteDisclosureIndicator.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
            cell.accessoryView = whiteDisclosureIndicator
            
            return cell
        }
        
        
        
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                print(1)
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
    extension ModifyGroupVC: UITextFieldDelegate {
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            nameField.resignFirstResponder()
            return true
        }
    }


//
//  ProfileVC.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 24/04/2023.
//
import Foundation
import UIKit
import FirebaseStorage

class ProfileVC: UIViewController{
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var level: UILabel!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let imagePickerController = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the navigation bar transparent (only needed in root page of controller)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: "button2") ?? UIColor.magenta]
        
        configureProfileViews()
        imagePickerController.delegate = self
        
        // Add UITapGestureRecognizer to profilImage view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGesture)
    }
    
    // display informations and set UI
    func configureProfileViews() {
        // Get profilImage URL
        let imageURL = FirebaseUser.shared.userInfo?.profile_picture ?? ""
        // Call function that load and display image
        FirebaseUser.shared.downloadProfileImageFromURL(url: imageURL) { data in
            if let data = data {
                self.profileImageView.image = UIImage(data: data)
            }
        }
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.gray.cgColor
        
        self.username.text = FirebaseUser.shared.userInfo?.username ?? "username"
        self.level.text = String(FirebaseUser.shared.userInfo?.points ?? 0)
        
        
    }
    
    // Call function to log out
     func logout() {
        FirebaseUser.shared.signOut { result in
            switch result {
            case .failure(let error): print(error)
            case .success(): self.performSegue(withIdentifier: "unwindToLogin", sender: self)
            }
        }
    }
    
    
    
    // Fonction qui sera appelée lorsque l'utilisateur appuie sur profileImageView.
    @objc func profileImageTapped() {
        // Effet de ressort
        CustomAnimations.imagePressAnimation(for: self.profileImageView) {
            
            let alert = UIAlertController(title: "Chose an image", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                self.openCamera()
            }))
            
            alert.addAction(UIAlertAction(title: "Galery", style: .default, handler: { _ in
                self.openGallery()
            }))
            
            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
}


// Extension for image picker, to change profil Image
extension ProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }
        else {
            print("Camera not available")
        }
    }
    
    func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            profileImageView.image = pickedImage
            
            if let imageData = pickedImage.jpegData(compressionQuality: 0.1) {
                FirebaseUser.shared.saveImageInStorage(imageData: imageData) { result in
                    switch result {
                    case .failure(let error):
                        print("Error saving image in storage:", error)
                    case .success(let downloadURL):
                        FirebaseUser.shared.saveProfileImage(url: downloadURL) { result in
                            switch result {
                            case .failure(let error):
                                print("Error saving profile image:", error)
                            case .success:
                                print("success saving profile image:")
                            }
                        }
                    }
                }
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
}

extension ProfileVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        
        let headerLabel = UILabel(frame: CGRect(x: 15, y: 0, width:
                                                    tableView.bounds.size.width, height: tableView.sectionHeaderHeight))
        headerLabel.font = UIFont(name: "Helvetica", size: 18)
        headerLabel.textColor = UIColor.white  // couleur du texte
        headerLabel.text = SettingsSections(rawValue: section)?.description
        headerLabel.sizeToFit()
        headerView.backgroundColor = UIColor(named: "background")
        headerView.addSubview(headerLabel)
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSections.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let settingsSection = SettingsSections(rawValue: section) else { return 0 }
        
        switch settingsSection {
        case .account: return SettingsSections.AccountOptions.allCases.count
        case .preferences: return SettingsSections.SecurityOptions.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? SettingsCell else {
            return UITableViewCell()
        }
        guard let settingsSection = SettingsSections(rawValue: indexPath.section) else { return cell }
        
        switch settingsSection {
        case .account:
            guard let accountOption = SettingsSections.AccountOptions(rawValue: indexPath.row) else { return UITableViewCell() }
            cell.sectionType = accountOption
            
        case .preferences:
            guard let securityOption = SettingsSections.SecurityOptions(rawValue: indexPath.row) else { return UITableViewCell() }
            cell.sectionType = securityOption
            
        }
        if !(cell.sectionType?.containsSwitch ?? false) {
//            cell.accessoryType = .disclosureIndicator
            let whiteDisclosureIndicator = UIImageView(image: UIImage(systemName: "chevron.right"))
            whiteDisclosureIndicator.tintColor = .white // Remplacez "customDisclosureIndicator" par le nom de votre image.
            whiteDisclosureIndicator.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
            cell.accessoryView = whiteDisclosureIndicator
        }
        
        
        
        cell.delegate = self
        
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SettingsSections(rawValue: section)?.description
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let settingsSection = SettingsSections(rawValue: indexPath.section) else { return }
        
        switch settingsSection {
        case .account:
            if let accountOption = SettingsSections.AccountOptions(rawValue: indexPath.row) {
                guard accountOption.segueIdentifier != "goToSocial" else { appDelegate.mainTabBarController?.selectedIndex = 2; return }
                
                guard accountOption.segueIdentifier != "goToDisconnect" else {logout(); return }
                if let identifier = accountOption.segueIdentifier {
                    performSegue(withIdentifier: identifier, sender: accountOption.description)
                }
            }
        case .preferences:
            if let securityOption = SettingsSections.SecurityOptions(rawValue: indexPath.row) {
                if let identifier = securityOption.segueIdentifier {
                    performSegue(withIdentifier: identifier, sender: securityOption.description)
                }
            }
        }
    }
}


extension ProfileVC: SettingsCellDelegate{
    func didChangeSwitchValue(in cell: SettingsCell, isOn: Bool) {
        print("1")
        switch isOn {
        case true : appDelegate.resumeSound()
        case false : appDelegate.stopSound()
        }
        UserDefaults.standard.setValue(isOn, forKey: "sound")
        UserDefaults.standard.synchronize()
    }
    
}

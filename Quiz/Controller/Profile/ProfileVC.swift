//
//  ProfileVC.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 24/04/2023.
//
import Foundation
import UIKit
import FirebaseStorage
import WebKit
// Class to see user profile
class ProfileVC: UIViewController{
    // Outlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var level: UILabel!
    // Properties
    let imagePickerController = UIImagePickerController() // Picker controller
    var activeAlert: UIAlertController? // For alert displaying
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePickerController.delegate = self
        
        // Add UITapGestureRecognizer to profilImage view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGesture)
    }
    
    // Method called when view will appear
    override func viewWillAppear(_ animated: Bool) {
        configureProfileViews()
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
        self.username.text = FirebaseUser.shared.userInfo?.username ?? "username"
        self.level.text = "\(FirebaseUser.shared.userInfo?.points ?? 0) xp"
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
    
    // allow user to choose between camera and galery when profile image is tapped
    @objc func profileImageTapped() {
        CustomAnimations.imagePressAnimation(for: self.profileImageView) {
            
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
            }
            
            let alert = UIAlertController(title: NSLocalizedString("Choose an image", comment: ""), message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Camera", comment: ""), style: .default, handler: { _ in
                self.openCamera()
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Gallery", comment: ""), style: .default, handler: { _ in
                self.openGallery()
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Delete current photo", comment: ""), style: .destructive, handler: { _ in
                self.deleteProfileImage()
            }))
            
            alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            
            self.activeAlert = alert
            
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    
    
}


// Extension for image picker, to change profil Image
extension ProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    // method to open the camera
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true, completion: nil)
        }
        else {
            print("Camera not available")
        }
    }
    
    // method to open the gallery
    func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    // method called when user finished picking a photo
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true, completion: nil)
            
            let consentAlert = UIAlertController(title: NSLocalizedString("Consent", comment: ""), message: NSLocalizedString("Do you agree to use this photo as a profile image visible to other users?", comment: ""), preferredStyle: .alert)
            
            consentAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { _ in
                self.uploadProfileImage(pickedImage: pickedImage)
            }))
            
            consentAlert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil))
            
            self.present(consentAlert, animated: true, completion: nil)
        }
    }
    
    // Method to upload picked image on firebase storage
    func uploadProfileImage(pickedImage: UIImage) {
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
    
    // Method to remove profile image from firebasse storage
    func deleteProfileImage() {
        FirebaseUser.shared.deleteImageInStorage { result in
            switch result {
            case .failure(let error):
                print("Error deleting image from storage:", error)
            case .success:
                // update UI by removing image
                self.profileImageView.image = UIImage(named: "plus")
                FirebaseUser.shared.deleteProfileImageURL(){result in
                    switch result {
                    case .success:  print("Successfully deleted profile image")
                    case .failure(let error): print(error)
                    }
                }
                
            }
        }
    }
    
    // called when user cancel the picking
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ProfileVC: UITableViewDelegate, UITableViewDataSource {
    // Create a custom header view for each section in the table view
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        
        // Create a label for the header
        let headerLabel = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.bounds.size.width, height: tableView.sectionHeaderHeight))
        headerLabel.font = UIFont(name: "Helvetica", size: 18)
        headerLabel.textColor = UIColor(named: "text") // Text color
        headerLabel.text = SettingsSections(rawValue: section)?.description
        headerLabel.sizeToFit()
        headerView.backgroundColor = UIColor(named: "background")
        headerView.addSubview(headerLabel)
        
        return headerView
    }
    
    // Set the height for each section's header
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    // Define the number of sections in the table view
    func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSections.allCases.count
    }
    
    // Define the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let settingsSection = SettingsSections(rawValue: section) else { return 0 }
        
        switch settingsSection {
        case .account: return SettingsSections.AccountOptions.allCases.count
        case .preferences: return SettingsSections.SecurityOptions.allCases.count
        case .privacy: return SettingsSections.PrivacyOptions.allCases.count
        }
    }
    
    // Configure and return a cell for a specific row
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
        case .privacy:
            guard let privacyOptions = SettingsSections.PrivacyOptions(rawValue: indexPath.row) else { return UITableViewCell() }
            cell.sectionType = privacyOptions
            
        }
        
        // Add a disclosure indicator to the cell if needed
        if !(cell.sectionType?.containsSwitch ?? false), let accountOption = cell.sectionType as? SettingsSections.AccountOptions, accountOption != .disconnect {
            cell.accessoryType = .disclosureIndicator
        }
        
        // Set the delegate of the cell to the view controller
        cell.delegate = self
        
        return cell
    }
    
    // Provide the title for each section's header
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SettingsSections(rawValue: section)?.description
    }
    
    // Handle row selection in the table view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let settingsSection = SettingsSections(rawValue: indexPath.section) else { return }
        
        switch settingsSection {
        case .account:
            if let accountOption = SettingsSections.AccountOptions(rawValue: indexPath.row) {
                guard accountOption.segueIdentifier != "goToDisconnect" else { logout(); return }
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
        case .privacy:
            if let privacyOptions = SettingsSections.PrivacyOptions(rawValue: indexPath.row) {
                if privacyOptions.isPrivacyPolicy {
                    displayPrivacyPolicyInWebView()
                }
            }
        }
    }
}


// Handle switches
extension ProfileVC: SettingsCellDelegate {

    // Function to handle changes in Sound switch
    func SoundSwitchChanged(in cell: SettingsCell, isOn: Bool) {
        switch isOn {
        case true:
            // If Sound is turned on, resume sound in the CustomTabBarController
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.resumeSound()
            }
        case false:
            // If Sound is turned off, stop sound in the CustomTabBarController
            if let tabBar = self.tabBarController as? CustomTabBarController {
                tabBar.stopSound()
            }
        }
        // Save Sound setting to UserDefaults
        UserDefaults.standard.setValue(isOn, forKey: "sound")
        UserDefaults.standard.synchronize()
    }
}


// Handle the displaying of privacy policy
extension ProfileVC {
    
    // Function to display the Privacy Policy in a WebView
    func displayPrivacyPolicyInWebView() {
        // Path to the PDF file
        if let pdfURL = Bundle.main.url(forResource: "privacy policy", withExtension: "pdf") {
            let webView = WKWebView()
            let request = URLRequest(url: pdfURL)
            webView.load(request)
            
            // Create a new UIViewController to display the WKWebView
            let webViewController = UIViewController()
            webViewController.view.addSubview(webView)
            webView.frame = webViewController.view.bounds
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // Push the new UIViewController onto the navigation stack
            self.navigationController?.pushViewController(webViewController, animated: true)
        }
    }
}

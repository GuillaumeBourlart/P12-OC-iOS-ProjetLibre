//
//  SocialVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 22/06/2023.
//

import Foundation
import UIKit

// controller in which you can choose to displaye Friends, Groups or invites
class SocialVC: UIViewController {
    // Outlets
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var friendsButton: CustomButton2!
    @IBOutlet weak var groupsButton: CustomButton2!
    @IBOutlet weak var invitesButton: CustomButton2!
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        // handle music
        if let tabBar = self.tabBarController as? CustomTabBarController {
            tabBar.playSound(soundName: "appMusic", fileType: "mp3")
        }
    }
    
    // Method called when view will appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reactivate buttons
        for button in buttons {
            button.isEnabled = true
            button.transform = .identity
            button.alpha = 1
        }
        // display images
        displayImages()
    }
    
    // function called when light mode change
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // update images in light/dark mode
            displayImages()
        }
    }
    
    // display images depending of light/dark mode
    func displayImages() {
        if traitCollection.userInterfaceStyle == .dark {
            // light mode
            friendsButton.setImage(UIImage(named: "friendsWhite"), for: .normal)
            groupsButton.setImage(UIImage(named: "groupsWhite"), for: .normal)
            invitesButton.setImage(UIImage(named: "invitesWhite"), for: .normal)
        } else {
            // dark mode
            friendsButton.setImage(UIImage(named: "friends"), for: .normal)
            groupsButton.setImage(UIImage(named: "groups"), for: .normal)
            invitesButton.setImage(UIImage(named: "invites"), for: .normal)
        }
    }
    
    // Prepare for the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let button = sender as? UIButton {
            button.isEnabled = false
            // Animate the button
            CustomAnimations.buttonPressAnimation(for: sender as! UIButton) {
                // play button sound
                if let tabBar = self.tabBarController as? CustomTabBarController {
                    tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
                }
                // disable every other buttons and move all buttons to the left
                for button in self.buttons {
                    button.isEnabled = false
                    UIView.animate(withDuration: 0.3, animations: {
                        button.transform = CGAffineTransform(translationX: -self.view.frame.width, y: 0)
                        button.alpha = 0
                    })
                    
                }
            }
        }
    }}

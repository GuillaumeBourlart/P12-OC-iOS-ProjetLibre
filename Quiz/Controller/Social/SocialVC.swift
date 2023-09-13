//
//  SocialVC.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 22/06/2023.
//

import Foundation
import UIKit

class SocialVC: UIViewController {
    @IBOutlet var buttons: [UIButton]!
    
    
    @IBOutlet weak var friendsButton: CustomButton2!
    @IBOutlet weak var groupsButton: CustomButton2!
    @IBOutlet weak var invitesButton: CustomButton2!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // handle music
        if let tabBar = self.tabBarController as? CustomTabBarController {
            tabBar.playSound(soundName: "appMusic", fileType: "mp3")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reactivate buttons
        for button in buttons {
            button.isEnabled = true
            button.transform = .identity
            button.alpha = 1
        }
        updateImageViewForCurrentTraitCollection()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                // Mettre à jour l'image lorsque le mode clair/sombre change
                updateImageViewForCurrentTraitCollection()
            }
        }

    func updateImageViewForCurrentTraitCollection() {
        if traitCollection.userInterfaceStyle == .dark {
            // Mode sombre
            friendsButton.setImage(UIImage(named: "friendsWhite"), for: .normal)
            groupsButton.setImage(UIImage(named: "groupsWhite"), for: .normal)
            invitesButton.setImage(UIImage(named: "invitesWhite"), for: .normal)
        } else {
            // Mode clair
            friendsButton.setImage(UIImage(named: "friends"), for: .normal)
            groupsButton.setImage(UIImage(named: "groups"), for: .normal)
            invitesButton.setImage(UIImage(named: "invites"), for: .normal)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let button = sender as? UIButton {
            button.isEnabled = false

            CustomAnimations.buttonPressAnimation(for: sender as! UIButton) {
                if let tabBar = self.tabBarController as? CustomTabBarController {
                    tabBar.playSoundEffect(soundName: "button", fileType: "mp3")
                }
                for button in self.buttons {
                    button.isEnabled = false

                    UIView.animate(withDuration: 0.3, animations: {
                        // Déplace le bouton vers la gauche en soustrayant la largeur de la vue du bouton
                        button.transform = CGAffineTransform(translationX: -self.view.frame.width, y: 0)
                        button.alpha = 0
                    })

                }
            }
        }
    }}

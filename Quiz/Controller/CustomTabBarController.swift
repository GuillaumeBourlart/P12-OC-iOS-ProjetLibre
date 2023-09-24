//
//  CustomTabBarController.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 12/09/2023.
//

import Foundation
import UIKit
import AVFoundation
// Class for the custom tabbar
class CustomTabBarController: UITabBarController {
    // Properties
    var musicPlayer: AVAudioPlayer? // AUdio player for music of app
    var soundEffectPlayer: AVAudioPlayer? // Audio player for sound effects
    var soundEffectPlayer2: AVAudioPlayer? // Second player for sound effects
    var countLabel: UILabel?
    
    // Method called when view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
    }
    
    // Set ui of the tabbar
    private func setupTabBar() {
        self.tabBar.tintColor = UIColor.white
        self.tabBar.isTranslucent = false
        self.tabBar.unselectedItemTintColor = UIColor.gray
        self.tabBar.barTintColor = UIColor.black
    }
    
    // HANDLE SOUNDS
    
    // Method to play the app music
    func playSound(soundName: String, fileType: String) {
        let defaults = UserDefaults.standard
        
        // Check if user disabled/enabled sound
        let sound: Bool
        if let _ = defaults.object(forKey: "sound") {
            sound = defaults.bool(forKey: "sound")
        } else {
            defaults.setValue(true, forKey: "sound")
            sound = true
        }
        
        // Sound volume
        let volume: Float = 0.1
        UserDefaults.standard.synchronize()
        
        if let path = Bundle.main.path(forResource: soundName, ofType: fileType) {
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                musicPlayer?.numberOfLoops = -1
                setVolume(volume: volume)
                
                // If sound is enabled, play the sound
                if sound {
                    musicPlayer?.play()
                }
            } catch {
                print("Could not find and play the sound file.")
            }
        }
    }
    
    // Method to play a sound effect
    func playSoundEffect(soundName: String, fileType: String) {
        if let path = Bundle.main.path(forResource: soundName, ofType: fileType) {
            do {
                // Check if a sound is already being played
                if soundEffectPlayer == nil || !soundEffectPlayer!.isPlaying {
                    soundEffectPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                    soundEffectPlayer?.play()
                } else {
                    // if a sound is being played, use the second AVAudioPlayer
                    soundEffectPlayer2 = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                    soundEffectPlayer2?.play()
                }
            } catch {
                print("Could not find and play the sound file.")
            }
        }
    }
    
    // Method to stop sound
    func stopSound() {
        musicPlayer?.stop()
    }
    
    // Method to play sound
    func resumeSound() {
        musicPlayer?.play()
    }
    
    // Method to change volume
    func setVolume(volume: Float) {
        musicPlayer?.volume = volume
    }
    // Method to show alert if joined invitation is expired
    func showSessionExpiredAlert() {
        let title = NSLocalizedString("Session Expired", comment: "Alert title for session expired")
        let message = NSLocalizedString("The invitation no longer exists.", comment: "Alert message for session expired")
        let okActionTitle = NSLocalizedString("OK", comment: "OK button title for alert")
        
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(
            title: okActionTitle,
            style: .default,
            handler: nil
        ))
        
        self.present(alertController, animated: true, completion: nil)
    }
}

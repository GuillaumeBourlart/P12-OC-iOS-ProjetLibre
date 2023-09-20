//
//  CustomTabBarController.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 12/09/2023.
//

import Foundation
import UIKit
import AVFoundation

class CustomTabBarController: UITabBarController {
    
    var musicPlayer: AVAudioPlayer?
    var soundEffectPlayer: AVAudioPlayer?
    var soundEffectPlayer2: AVAudioPlayer?
    var countLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
    }

    private func setupTabBar() {
        self.tabBar.tintColor = UIColor.white
        self.tabBar.isTranslucent = false
        self.tabBar.unselectedItemTintColor = UIColor.gray
        self.tabBar.barTintColor = UIColor.black
    }
    
    
    // HANDLE SOUNDS
    func playSound(soundName: String, fileType: String) {
        let defaults = UserDefaults.standard

        let sound: Bool
        if let _ = defaults.object(forKey: "sound") {
            // L'utilisateur a déjà défini une valeur pour "sound", utilisez cette valeur.
            sound = defaults.bool(forKey: "sound")
        } else {
            // L'utilisateur n'a jamais défini une valeur pour "sound", utilisez une valeur par défaut.
            defaults.setValue(true, forKey: "sound")
            sound = true
        }

        let volume: Float = 0.1
        UserDefaults.standard.synchronize()

        if let path = Bundle.main.path(forResource: soundName, ofType: fileType) {
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                musicPlayer?.numberOfLoops = -1
                setVolume(volume: volume)
                // Si le son est désactivé, ne jouez pas le son et retournez de la fonction
                if sound {
                    musicPlayer?.play()
                }
            } catch {
                print("Could not find and play the sound file.")
            }
        }
    }
    
    func playSoundEffect(soundName: String, fileType: String) {
        if let path = Bundle.main.path(forResource: soundName, ofType: fileType) {
            do {
                if soundEffectPlayer == nil || !soundEffectPlayer!.isPlaying {
                    soundEffectPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                    soundEffectPlayer?.play()
                } else {
                    soundEffectPlayer2 = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                    soundEffectPlayer2?.play()
                }
            } catch {
                print("Could not find and play the sound file.")
            }
        }
    }
    
    func stopSound() {
        musicPlayer?.stop()
        
    }
    func resumeSound() {
        musicPlayer?.play()
    }
    func setVolume(volume: Float) {
        musicPlayer?.volume = volume
    }
    
   
}

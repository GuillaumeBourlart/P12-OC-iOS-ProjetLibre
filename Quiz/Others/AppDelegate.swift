//
//  AppDelegate.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 13/05/2023.
//

import UIKit
import CoreData
import FirebaseCore
import FirebaseMessaging
import AVFoundation


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var audioPlayer: AVAudioPlayer?
    
    let gcmMessageIDKey = "gcm.message_id"
    
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Firebase
                FirebaseApp.configure()

                // Request permission for notifications
                registerForPushNotifications()

                // Set the delegate for the User Notification Center
                UNUserNotificationCenter.current().delegate = self
                
                // Set the delegate for Firebase Messaging
                Messaging.messaging().delegate = self
        
        return true
    }
    
    // This function requests permission to send the user notifications.
        func registerForPushNotifications() {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    guard granted else { return }
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
            }
        }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "Quiz")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate{
 
    // This function is called when the app successfully registers for push notifications.
        func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            // Pass device token to Firebase Messaging
            Messaging.messaging().apnsToken = deviceToken
        }

        // This function is called when Firebase generates a new messaging token.
        func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
            guard let fcmToken = fcmToken else { return }
            let firebaseService = FirebaseService()
            let dataDict:[String: String] = ["token": fcmToken]
            // If the currentUserID exists, store the token in Firestore.
            if let currentUserID = FirebaseService().currentUserID {
                firebaseService.updateDocument(in: "users", documentId: currentUserID, data: dataDict) { error in
                    if let error = error {
                        print("Error saving FCM token: \(error)")
                    } else {
                        print("FCM token saved successfully!")
                    }
                }
            }
        }
    
    // This function is called when the app fails to register for push notifications.
        func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
            print("Failed to register for remote notifications: \(error.localizedDescription)")
        }

        // This function handles push notifications when the app is in the foreground.
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            let userInfo = notification.request.content.userInfo
            handleNotification(userInfo: userInfo)

            // Display notification alert and play a sound
            completionHandler([.alert, .sound])
        }

        // This function handles push notifications when the user taps on them.
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
            let userInfo = response.notification.request.content.userInfo
            handleNotification(userInfo: userInfo)
            
                guard let notificationType = userInfo["notificationType"] as? String else {
                    completionHandler()
                    return
                }

            switch notificationType {
                case "gameInvitation":
                    guard let lobbyID = userInfo["lobbyID"] as? String else {
                        completionHandler()
                        return
                    }
                    // Utilisez lobbyID pour rejoindre le jeu
                    joinGameFromInvitation(lobbyID: lobbyID)
                case "friendRequest":
                    // Allez à la page d'amis
                    navigateToFriendsPage()
                default:
                    break
                }

            completionHandler()
        }
    
    // This function handles silent push notifications (also known as data notifications).
        func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                         fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            handleNotification(userInfo: userInfo)

            completionHandler(.newData)
        }

        // This function determines what action to take based on the notification.
        private func handleNotification(userInfo: [AnyHashable : Any]) {
            // Insert notification handling code here.
            // You can perform a switch on userInfo to determine what action to take.
            guard let notificationType = userInfo["notificationType"] as? String else { return }

            switch notificationType {
                case "gameInvitation":
                    guard let lobbyID = userInfo["lobbyID"] as? String else { return }
                    // Utilisez lobbyID pour actualiser les invitations
                FirebaseUser.shared.getUserInfo { result in
                    switch result {
                    case .failure(let error): print(error)
                    case .success(): print("success")
                        NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
                    }

                }
                case "friendRequest":
                    // Actualisez les demandes d'amis
                FirebaseUser.shared.getUserInfo { result in
                    switch result {
                    case .failure(let error): print(error)
                    case .success(): print("success")
                        NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
                    }
                }
            case "friendRequestAccepted":
                // Actualisez les demandes d'amis
            FirebaseUser.shared.getUserInfo { result in
                switch result {
                case .failure(let error): print(error)
                case .success(): print("success")
                    NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
                }
            }
            case "friendRequestRejected":
                // Actualisez les demandes d'amis
            FirebaseUser.shared.getUserInfo { result in
                switch result {
                case .failure(let error): print(error)
                case .success(): print("success")
                    NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
                }
            }
            case "friendRemoved":
                // Actualisez les demandes d'amis
            FirebaseUser.shared.getUserInfo { result in
                switch result {
                case .failure(let error): print(error)
                case .success(): print("success")
                    NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
                }
            }
                default:
                    break
                }
        }
    
    func navigateToFriendsPage() {
        // Obtenez le contrôleur de vue actuel
        guard let tabBarController = window?.rootViewController as? UITabBarController else {
            print("Unable to find the tab bar controller.")
            return
        }
        
        // Sélectionnez le navigationController contenant la page Profil
        // Ici, on suppose que le navigationController est le deuxième onglet. Modifiez l'index en fonction de votre configuration.
        tabBarController.selectedIndex = 1
        
        // Assurez-vous que le navigationController est bien le contrôleur de vue sélectionné
        guard let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            print("Expected a navigation controller.")
            return
        }
        
        // Retour à la vue de base
        navigationController.popToRootViewController(animated: false)
        
        // Naviguez vers la page Profil, si ce n'est pas déjà la vue de base
        if !(navigationController.topViewController is ProfilVC) {
            let profileViewController = ProfilVC() // Initialisez votre contrôleur de vue Profil ici
            navigationController.pushViewController(profileViewController, animated: false)
        }
        
        // Naviguez vers la page Amis
        let friendsViewController = FriendsVC() // Initialisez votre contrôleur de vue Amis ici
        navigationController.pushViewController(friendsViewController, animated: true)
    }
    
    func joinGameFromInvitation(lobbyID: String) {
        // Obtenez le contrôleur de vue actuel
        guard let tabBarController = window?.rootViewController as? UITabBarController else {
            print("Unable to find the tab bar controller.")
            return
        }
        
        // Sélectionnez le navigationController contenant la page Profil
        // Ici, on suppose que le navigationController est le deuxième onglet. Modifiez l'index en fonction de votre configuration.
        tabBarController.selectedIndex = 1
        
        // Assurez-vous que le navigationController est bien le contrôleur de vue sélectionné
        guard let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            print("Expected a navigation controller.")
            return
        }
        
        // Retour à la vue de base
        navigationController.popToRootViewController(animated: false)
        
        Game.shared.joinRoom(lobbyId: lobbyID) { result in
            switch result {
            case .failure(let error): print(error)
            case .success():
                // Naviguez vers la page Profil, si ce n'est pas déjà la vue de base
                if !(navigationController.topViewController is ProfilVC) {
                    let profileViewController = ProfilVC() // Initialisez votre contrôleur de vue Profil ici
                    navigationController.pushViewController(profileViewController, animated: false)
                }
                
                // Naviguez vers la page Amis
                let friendsViewController = PrivateLobbyVC() // Initialisez votre contrôleur de vue Amis ici
                navigationController.pushViewController(friendsViewController, animated: true)
            }
        }
        
    }


}


// Handle de sound in the app
extension AppDelegate {
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

        let volume: Float
        if let _ = defaults.object(forKey: "volume") {
            // L'utilisateur a déjà défini une valeur pour "volume", utilisez cette valeur.
            volume = defaults.float(forKey: "volume")
        } else {
            // L'utilisateur n'a jamais défini une valeur pour "volume", utilisez une valeur par défaut.
            defaults.setValue(0.5, forKey: "volume")
            volume = 0.5
        }
        UserDefaults.standard.synchronize()

        if let path = Bundle.main.path(forResource: soundName, ofType: fileType) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                setVolume(volume: volume)
                // Si le son est désactivé, ne jouez pas le son et retournez de la fonction
                if sound {
                    audioPlayer?.play()
                }
            } catch {
                print("Could not find and play the sound file.")
            }
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
        
    }
    func resumeSound() {
        audioPlayer?.play()
    }
    func setVolume(volume: Float) {
        audioPlayer?.volume = volume
    }
}

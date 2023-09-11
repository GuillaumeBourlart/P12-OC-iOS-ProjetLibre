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
    var musicPlayer: AVAudioPlayer?
    var soundEffectPlayer: AVAudioPlayer?
    var soundEffectPlayer2: AVAudioPlayer?
    
    let gcmMessageIDKey = "gcm.message_id"
    var mainTabBarController: UITabBarController? {
        didSet {
            self.mainTabBarController?.tabBar.tintColor = UIColor.black // Remplacer par la couleur désirée pour le fond
            self.mainTabBarController?.tabBar.isTranslucent = false // Rend la TabBar non translucide

               // Fixe la couleur des icônes et du texte non sélectionnés
            self.mainTabBarController?.tabBar.unselectedItemTintColor = UIColor.gray // Remplacer par la couleur désirée pour les éléments non sélectionnés

               // Fixe la couleur des icônes et du texte sélectionnés
            self.mainTabBarController?.tabBar.tintColor = UIColor.white
            
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Firebase
                FirebaseApp.configure()

                // Request permission for notifications
                registerForPushNotifications()

                // Set the delegate for the User Notification Center
                UNUserNotificationCenter.current().delegate = self
                
                // Set the delegate for Firebase Messaging
                Messaging.messaging().delegate = self
        
        //checkdarMode
        checkdarkMode()
        
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

protocol LeavePageProtocol {
    func leavePage(completion: @escaping () -> Void)
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

//        // This function handles push notifications when the app is in the foreground.
//        func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                    willPresent notification: UNNotification,
//                                    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//            let userInfo = notification.request.content.userInfo
//            handleNotification(userInfo: userInfo)
//
//            // Display notification alert and play a sound
//            completionHandler([.banner, .sound])
//        }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        handleNotification(userInfo: userInfo)
        
        // Obtenez le type de notification
        guard let notificationType = userInfo["notificationType"] as? String else {
            completionHandler([])
            return
        }
        
        // Affichez seulement certains types de notifications
        switch notificationType {
        case "gameInvitation", "friendRequest", "friendRequestAccepted":
            completionHandler([.banner, .sound])
        default:
            completionHandler([])
        }
    }
    
    func getTopViewController(_ base: UIViewController? = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return getTopViewController(nav.visibleViewController)
        }

        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(selected)
        }

        if let presented = base?.presentedViewController {
            return getTopViewController(presented)
        }

        return base
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo: userInfo)
        
        guard let notificationType = userInfo["notificationType"] as? String else {
            completionHandler()
            return
        }
        if let currentViewController = getTopViewController(), let viewControllerToLeave = currentViewController as? LeavePageProtocol {
            viewControllerToLeave.leavePage {
                switch notificationType {
                case "gameInvitation":
                    guard let lobbyID = userInfo["lobbyID"] as? String else {
                        completionHandler()
                        return
                    }
                    self.joinGameFromInvitation(lobbyID: lobbyID)
                case "friendRequest":
                    self.navigateToFriendsPage()
                default:
                    break
                }
                completionHandler()
            }
        } else {
            switch notificationType {
            case "gameInvitation":
                guard let lobbyID = userInfo["lobbyID"] as? String else {
                    completionHandler()
                    return
                }
                self.joinGameFromInvitation(lobbyID: lobbyID)
            case "friendRequest":
                self.navigateToFriendsPage()
            default:
                break
            }
            completionHandler()
        }
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
                guard userInfo["lobbyID"] is String else { return }
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
            case "friendRequestCancelled":
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
            guard let tabBarController = mainTabBarController else {
                print("Unable to find the tab bar controller.")
                return
            }
        
        
        // Sélectionnez le navigationController contenant la page Profil
        // Ici, on suppose que le navigationController est le deuxième onglet. Modifiez l'index en fonction de votre configuration.
        tabBarController.selectedIndex = 2
        
        // Assurez-vous que le navigationController est bien le contrôleur de vue sélectionné
        guard let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            print("Expected a navigation controller.")
            return
        }
        
        // Retour à la vue de base
        navigationController.popToRootViewController(animated: false)
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Remplacez "Main" par le nom de votre storyboard
        // Naviguez vers la page Profil, si ce n'est pas déjà la vue de base
        if !(navigationController.topViewController is SocialVC) {
            
            if let profileViewController = storyboard.instantiateViewController(withIdentifier: "ProfilVC") as? SocialVC {
                // Utilisez friendsViewController ici
                navigationController.pushViewController(profileViewController, animated: false)
            }
        }
        
        
        if let friendsViewController = storyboard.instantiateViewController(withIdentifier: "FriendsVC") as? FriendsVC {
            // Utilisez friendsViewController ici
            navigationController.pushViewController(friendsViewController, animated: true)
        }
        
    }
    
    func joinGameFromInvitation(lobbyID: String) {
        Game.shared.joinRoom(lobbyId: lobbyID) { result in
            switch result {
            case .failure(let error): print(error)
            case .success():
                // Obtenez le contrôleur de vue actuel
                guard let tabBarController = self.mainTabBarController else {
                        print("Unable to find the tab bar controller.")
                        return
                    }
                
                tabBarController.selectedIndex = 0
                
                // Assurez-vous que le navigationController est bien le contrôleur de vue sélectionné
                guard let navigationController = tabBarController.selectedViewController as? UINavigationController else {
                    print("Expected a navigation controller.")
                    return
                }
                
                // Retour à la vue de base
                navigationController.popToRootViewController(animated: false)
                let storyboard = UIStoryboard(name: "Main", bundle: nil) // Remplacez "Main" par le nom de votre storyboard
                // Naviguez vers la page Profil, si ce n'est pas déjà la vue de base
                if !(navigationController.topViewController is QuickPlayVC) {
                    
                    if let profileViewController = storyboard.instantiateViewController(withIdentifier: "HomeVC") as? QuickPlayVC {
                        // Utilisez friendsViewController ici
                        navigationController.pushViewController(profileViewController, animated: false)
                    }
                }
                
                
                if let roomViewController = storyboard.instantiateViewController(withIdentifier: "PrivateLobbyVC") as? PrivateLobbyVC {
                    // Ici, vous pouvez définir les propriétés nécessaires sur `roomViewController`
                        roomViewController.lobbyId = lobbyID
                        roomViewController.isCreator = false
                    // Utilisez friendsViewController ici
                    navigationController.pushViewController(roomViewController, animated: true)
                }
            }
        }
        
    }


}


// Handle sound and darkmode in the app
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
    
    func checkdarkMode() {
        // Vérifiez la valeur enregistrée pour "darkmode" dans UserDefaults
                let defaults = UserDefaults.standard
                if let darkModeOn = defaults.object(forKey: "darkmode") as? Bool {
                    // Si darkModeOn est true, réglez le style d'interface utilisateur sur .dark, sinon sur .light
                    if darkModeOn {
                        window?.overrideUserInterfaceStyle = .dark
                    } else {
                        window?.overrideUserInterfaceStyle = .light
                    }
                } else {
                    // Si aucune valeur n'est enregistrée pour "darkmode", réglez le style d'interface utilisateur sur le style par défaut
                    window?.overrideUserInterfaceStyle = .unspecified
                }
        
    }
}



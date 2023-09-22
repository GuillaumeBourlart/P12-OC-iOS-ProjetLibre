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
import FirebasePerformance



@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    var mainTabBarController: UITabBarController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Request permission for notifications
        registerForPushNotifications()
        
        // Set the delegate for the User Notification Center
        UNUserNotificationCenter.current().delegate = self
        
        // Set the delegate for Firebase Messaging
        Messaging.messaging().delegate = self
        
        // chech firebase performance consent
        if let userAnswerExists = UserDefaults.standard.object(forKey: "firebasePerformanceEnabled") as? Bool {
            Performance.sharedInstance().isDataCollectionEnabled = userAnswerExists
        } else {
            Performance.sharedInstance().isDataCollectionEnabled = true // Activate firebase performance until the consent alert is displayed
        }
        
        // check current phone mode
        checkDarkMode()
        
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

// handle notifications
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
    
    
    // Function to determine how to present a notification when it's received in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Extract the user info from the notification.
        let userInfo = notification.request.content.userInfo
        
        // Handle the incoming notification.
        handleNotification(userInfo: userInfo)
        
        // Determine the type of notification.
        guard let notificationType = userInfo["notificationType"] as? String else {
            completionHandler([])
            return
        }
        
        // Specify how the notification should be presented based on its type.
        switch notificationType {
        case "gameInvitation", "friendRequest", "friendRequestAccepted":
            completionHandler([.banner, .sound])
        default:
            completionHandler([])
        }
    }
    
    // Function to retrieve the top-most visible view controller.
    func getTopViewController(_ base: UIViewController? = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first?.rootViewController) -> UIViewController? {
            
            // If the base controller is a navigation controller, get its top-most controller.
            if let nav = base as? UINavigationController {
                return getTopViewController(nav.visibleViewController)
            }
            
            // If the base controller is a tab bar controller, get the selected controller.
            if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
                return getTopViewController(selected)
            }
            
            // If there's a presented view controller, get it.
            if let presented = base?.presentedViewController {
                return getTopViewController(presented)
            }
            
            // If none of the above, return the base.
            return base
        }
    
    // Function to handle user actions in response to a delivered notification.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extract user info from the notification response.
        let userInfo = response.notification.request.content.userInfo
        
        // Handle the user's response to the notification.
        handleNotification(userInfo: userInfo)
        
        // Determine the type of the notification.
        guard let notificationType = userInfo["notificationType"] as? String else {
            completionHandler()
            return
        }
        
        // Check if the current top-most view controller conforms to the `LeavePageProtocol`.
        // If yes, trigger the `leavePage` action. Else, handle the notification directly.
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
    
    
    // Function to handle notifications based on the provided user info.
    private func handleNotification(userInfo: [AnyHashable : Any]) {
        // Retrieve the type of notification from user info.
        guard let notificationType = userInfo["notificationType"] as? String else { return }
        
        switch notificationType {
        case "gameInvitation":
            // Check if a lobby ID is present for game invitation notifications.
            guard userInfo["lobbyID"] is String else { return }
            // Update the user's information.
            updateUserInfo()
            
            // Handle multiple friend-related notification types.
        case "friendRequest",
            "friendRequestAccepted",
            "friendRequestCancelled",
            "friendRequestRejected",
            "friendRemoved":
            // Update the user's information.
            updateUserInfo()
            
        default:
            // If the notification type is not recognized, do nothing.
            break
        }
    }
    
    // Function to retrieve and update the user's information from Firebase.
    private func updateUserInfo() {
        // Request user information from Firebase.
        FirebaseUser.shared.getUserInfo { result in
            switch result {
            case .failure(let error):
                // If there's an error, print it.
                print(error)
            case .success():
                // If successful, print success and post a notification to update data.
                print("success")
                NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
            }
        }
    }
    
    // Navigate to friends page from any location
    func navigateToFriendsPage() {
        guard let tabBarController = mainTabBarController else {
            print("Unable to find the tab bar controller.")
            return
        }
        
        // Assuming the navigation controller containing the profile page is the third tab
        tabBarController.selectedIndex = 2
        
        guard let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            print("Expected a navigation controller.")
            return
        }
        
        navigateToSocialIfNeeded(on: navigationController)
        navigateToFriends(on: navigationController)
    }
    
    // Navigate to the social view controller if not already displayed
    private func navigateToSocialIfNeeded(on navigationController: UINavigationController) {
        navigationController.popToRootViewController(animated: false)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if !(navigationController.topViewController is SocialVC),
           let profileViewController = storyboard.instantiateViewController(withIdentifier: "SocialVC") as? SocialVC {
            navigationController.pushViewController(profileViewController, animated: false)
        }
    }
    
    // Navigate to the friends view controller
    private func navigateToFriends(on navigationController: UINavigationController) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let friendsViewController = storyboard.instantiateViewController(withIdentifier: "FriendsVC") as? FriendsVC {
            friendsViewController.initialSegmentIndex = 1
            navigationController.pushViewController(friendsViewController, animated: true)
        }
    }
    
    // Function to join a game based on the provided lobby ID
    func joinGameFromInvitation(lobbyID: String) {
        // delete the invite after user clicked on it
        Game.shared.deleteInvite(inviteId: lobbyID) { result in
            switch result {
            case .failure(let error): print(error)
            case .success(let lobbyID): print("invite \(lobbyID) deleted")
            }
            // Attempt to join the game room
            Game.shared.joinRoom(lobbyId: lobbyID) { result in
                switch result {
                case .failure(let error):
                    // Print the error if joining fails
                    print(error)
                case .success():
                    // Navigate to the appropriate view controller if joining is successful
                    self.navigateAfterJoining(lobbyID: lobbyID)
                }
            }
        }
        
    }
    // Function to navigate the user to the relevant view controller after successfully joining the game
    func navigateAfterJoining(lobbyID: String) {
        // Ensure the main tab bar controller exists
        guard let tabBarController = self.mainTabBarController else {
            print("Unable to find the tab bar controller.")
            return
        }
        
        // Set the selected index to the first tab
        tabBarController.selectedIndex = 0
        
        // Ensure the selected view controller is a navigation controller
        guard let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            print("Expected a navigation controller.")
            return
        }
        
        // Navigate to the profile view controller if it's not already visible
        self.navigateToProfileIfNeeded(on: navigationController)
        // Navigate to the room view controller
        self.navigateToRoom(lobbyID: lobbyID, on: navigationController)
    }
    
    // Function to navigate to the profile view controller if it's not already the top view controller
    func navigateToProfileIfNeeded(on navigationController: UINavigationController) {
        // Navigate to the root view controller of the navigation stack
        navigationController.popToRootViewController(animated: false)
        
        // Retrieve the main storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Check if the top view controller isn't the QuickPlayVC
        if !(navigationController.topViewController is QuickPlayVC),
           let profileViewController = storyboard.instantiateViewController(withIdentifier: "QuickPlayVC") as? QuickPlayVC {
            // Push the profile view controller to the navigation stack
            navigationController.pushViewController(profileViewController, animated: false)
        }
    }
    
    // Function to navigate to the room view controller and set its properties
    func navigateToRoom(lobbyID: String, on navigationController: UINavigationController) {
        // Retrieve the main storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Instantiate the room view controller from the storyboard
        if let roomViewController = storyboard.instantiateViewController(withIdentifier: "PrivateLobbyVC") as? PrivateLobbyVC {
            // Set the properties of the room view controller
            roomViewController.lobbyId = lobbyID
            roomViewController.isCreator = false
            
            // Push the room view controller to the navigation stack
            navigationController.pushViewController(roomViewController, animated: true)
        }
    }
}

// Handle dark mode settings in the app
extension AppDelegate {
    
    func checkDarkMode() {
        // Check the saved value for "darkmode" in UserDefaults
        let defaults = UserDefaults.standard
        if let darkModeOn = defaults.object(forKey: "darkmode") as? Bool {
            // If darkModeOn is true, set the UI style to .dark, otherwise to .light
            if darkModeOn {
                window?.overrideUserInterfaceStyle = .dark
            } else {
                window?.overrideUserInterfaceStyle = .light
            }
        } else {
            // If no value is saved for "darkmode", set the UI style to the default style
            window?.overrideUserInterfaceStyle = .unspecified
        }
    }
}




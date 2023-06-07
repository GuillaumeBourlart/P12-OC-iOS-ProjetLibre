//
//  Settings.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 02/05/2023.
//

import Foundation
// Structure to set section et rows in parameters
enum SettingsSection: Int, CaseIterable {
    case account = 0
    case security
    // title
    var title: String {
        switch self {
        case .account:
            return "Compte"
        case .security:
            return "Sécurité"
        }
    }
    // Section 1
    enum Account: Int, CaseIterable {
        case friends
        case group
        case history
        case quizzes
        case invites
        // titles
        var title: String {
            switch self {
            case .friends:
                return "Amis"
            case .group:
                return "Groupe"
            case .history:
                return "Historique"
            case .quizzes:
                return "Quizzes"
            case .invites:
                return "Invites"
            }
        
        }
        // Segue's IDS
        var segueIdentifier: String {
            switch self {
            case .friends:
                return "goToFriends"
            case .group:
                return "goToQuizzOrGroups"
            case .history:
                return "goToHistory"
            case .quizzes:
                return "goToQuizzOrGroups"
            case .invites:
                return "goToInvites"
            }
        }
    }
    // Section 2
    enum Security: Int, CaseIterable {
        case option1
        case option2
        case option3
        case option4
        case option5
        case option6
        // titles
        var title: String {
            return "Option Sécurité \(self.rawValue + 1)"
        }
        // segue's IDS
        var segueIdentifier: String {
            return "showSecurityOption\(self.rawValue + 1)"
        }
    }
    
}

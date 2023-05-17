//
//  Settings.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 02/05/2023.
//

import Foundation

enum SettingsSection: Int, CaseIterable {
    case account = 0
    case security
    
    var title: String {
        switch self {
        case .account:
            return "Compte"
        case .security:
            return "Sécurité"
        }
    }
    
    enum Account: Int, CaseIterable {
        case friends
        case group
        case history
        case quizzes
        
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
            }
        }
        
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
            }
        }
    }
    
    enum Security: Int, CaseIterable {
        case option1
        case option2
        case option3
        case option4
        case option5
        case option6
        
        var title: String {
            return "Option Sécurité \(self.rawValue + 1)"
        }
        
        var segueIdentifier: String {
            return "showSecurityOption\(self.rawValue + 1)"
        }
    }
    
}

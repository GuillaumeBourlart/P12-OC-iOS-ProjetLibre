//
//  Settings.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 02/05/2023.
//

import Foundation
// Structure to set section et rows in parameters

protocol SectionType: CustomStringConvertible{
    var containsSwitch: Bool{ get }
}


enum SettingsSections: Int, CaseIterable, CustomStringConvertible {
    case account
    case preferences
    // title
    var description: String {
        switch self {
        case .account: return NSLocalizedString("Account", comment: "")
        case .preferences: return NSLocalizedString("Preferences", comment: "")
        }
    }
    // Section 1
    enum AccountOptions: Int, CaseIterable, SectionType {
        case friends
        case group
        case history
        case quizzes
        case invites
        // titles
        var description: String {
            switch self {
                        case .friends:
                            return NSLocalizedString("Friends", comment: "")
                        case .group:
                            return NSLocalizedString("Groups", comment: "")
                        case .history:
                            return NSLocalizedString("History", comment: "")
                        case .quizzes:
                            return NSLocalizedString("Quizzes", comment: "")
                        case .invites:
                            return NSLocalizedString("Invites", comment: "")
                        }
            
        }
        // Segue's IDS
        var segueIdentifier: String? {
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
        
        var containsSwitch: Bool {
            return false
        }
        
    }
    
    // Section 2
    enum SecurityOptions: Int, CaseIterable, SectionType {
        case sounds
        // titles
        var description: String {
            switch self {
            case .sounds:
                return NSLocalizedString("Sounds", comment: "")
            }
        }
        // segue's IDS
        var segueIdentifier: String? {
            switch self {
            case .sounds:
                return nil
            }
        }
        
        var containsSwitch: Bool {
            switch self {
            case .sounds: return true
            }
        }
    }
}


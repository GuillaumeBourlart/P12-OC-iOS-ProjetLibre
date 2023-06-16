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
        case .account: return "Account"
        case .preferences: return "Preferences"
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
                return "Friends"
            case .group:
                return "Groups"
            case .history:
                return "History"
            case .quizzes:
                return "Quizzes"
            case .invites:
                return "Invites"
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
        case language
        // titles
        var description: String {
            switch self {
            case .sounds:
                return "Sounds"
            case .language:
                return "Language"
            }
        }
        // segue's IDS
        var segueIdentifier: String? {
            switch self {
            case .sounds:
                return nil
            case .language: return "goToLanguageSelection"
            }
        }
        
        var containsSwitch: Bool {
            switch self {
            case .sounds: return true
            case .language: return false
            }
        }
        
    }
    
}

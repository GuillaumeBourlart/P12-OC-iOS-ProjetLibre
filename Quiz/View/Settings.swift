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
        case social
        case history
        case quizzes
        case disconnect
        // titles
        var description: String {
            switch self {
                        case .social:
                            return NSLocalizedString("Social", comment: "")
                        case .history:
                            return NSLocalizedString("History", comment: "")
                        case .quizzes:
                            return NSLocalizedString("Quizzes", comment: "")
            case .disconnect:
                return NSLocalizedString("Disconnect", comment: "")
            }
            
        }
        // Segue's IDS
        var segueIdentifier: String? {
            switch self {
            case .social:
                return "goToSocial"
            case .history:
                return "goToHistory"
            case .quizzes:
                return "goToQuizzOrGroups"
            case .disconnect:
                return "goToDisconnect"
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


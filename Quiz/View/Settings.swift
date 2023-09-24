//
//  Settings.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 02/05/2023.
//

import Foundation

// Protocol to define section types
protocol SectionType: CustomStringConvertible {
    var containsSwitch: Bool { get }
}

// Enumeration for different sections in the settings
enum SettingsSections: Int, CaseIterable, CustomStringConvertible {
    case account
    case preferences
    case privacy
    
    // Title for each section
    var description: String {
        switch self {
        case .account: return NSLocalizedString("Account", comment: "")
        case .preferences: return NSLocalizedString("Preferences", comment: "")
        case .privacy: return NSLocalizedString("Privacy", comment: "")
        }
    }
    
    // Enumeration for options within the "Account" section
    enum AccountOptions: Int, CaseIterable, SectionType {
        case history
        case quizzes
        case disconnect
        
        // Titles for each option
        var description: String {
            switch self {
            case .history: return NSLocalizedString("History", comment: "")
            case .quizzes: return NSLocalizedString("Quizzes", comment: "")
            case .disconnect: return NSLocalizedString("Disconnect", comment: "")
            }
        }
        
        // Segue identifiers for each option
        var segueIdentifier: String? {
            switch self {
            case .history: return "goToHistory"
            case .quizzes: return "goToQuizzOrGroups"
            case .disconnect: return "goToDisconnect"
            }
        }
        
        // Indicates whether the option contains a switch
        var containsSwitch: Bool {
            return false
        }
    }
    
    // Enumeration for options within the "Security" section
    enum SecurityOptions: Int, CaseIterable, SectionType {
        case sounds
        
        // Titles for each option
        var description: String {
            switch self {
            case .sounds: return NSLocalizedString("Sounds", comment: "")
            }
        }
        
        // Segue identifiers for each option
        var segueIdentifier: String? {
            switch self {
            case .sounds: return nil
            }
        }
        
        // Indicates whether the option contains a switch
        var containsSwitch: Bool {
            switch self {
            case .sounds: return true
            }
        }
    }
    
    // Enumeration for options within the "Privacy" section
    enum PrivacyOptions: Int, CaseIterable, SectionType {
        case privacypolicy
        
        // Titles for each option
        var description: String {
            switch self {
            case .privacypolicy: return NSLocalizedString("Privacy policy", comment: "")
            }
        }
        
        // Segue identifier for the option
        var segueIdentifier: String? {
            switch self {
            case .privacypolicy: return "goToPrivacy"
            }
        }
        
        // Indicates whether the option is for privacy policy
        var isPrivacyPolicy: Bool {
            switch self {
            case .privacypolicy: return true
            }
        }
        
        // Indicates whether the option contains a switch
        var containsSwitch: Bool {
            switch self {
            case .privacypolicy: return false
            }
        }
    }
}



//
//  File.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 29/05/2023.
//

import Foundation
// Enume to chose what king of friend invites we want to fetch in fetchFriendRequests()
enum Status: String  {
    case received = "received"
    case sent = "sent"
}

// Fields name for firebase firestore
struct FirestoreFields {
    
    // Collection names
    static let usersCollection = "users"
    static let quizzesCollection = "quizzes"
    static let gamesCollection = "games"
    static let lobbyCollection = "lobby"
    static let groupsCollection = "groups"
    
    // Common field names
    static let id = "id"
    static let creator = "creator"
    static let status = "status"
    static let date = "date"
    
    // User fields
    struct User {
        static let username = "username"
        static let email = "email"
        static let firstName = "first_name"
        static let lastName = "last_name"
        static let birthDate = "birth_date"
        static let inscriptionDate = "inscription_date"
        static let rank = "rank"
        static let points = "points"
        static let fcmToken = "fcmToken"
        static let invites = "invites"
        static let profilePicture = "profile_picture"
        static let friends = "friends"
        static let friendRequests = "friendRequests"
        static let senderUsername = "username"
    }
    
    // Quiz fields
    struct Quiz {
        static let name = "name"
        static let categoryId = "category_id"
        static let difficulty = "difficulty"
        static let averageScore = "average_score"
        static let usersCompleted = "users_completed"
        static let code = "code"
        static let questions = "questions"
    }
    
    struct Question {
        static let question = "question"
        static let incorrectAnswers = "incorrect_answers"
        static let correctAnswer = "correct_answer"
        static let explanation = "explanation"
        static let category = "category"
        static let type = "type"
        static let difficulty = "difficulty"
    }
    
    // Game fields
    struct Game {
        static let competitive = "competitive"
        static let players = "players"
        static let quizId = "quiz_id"
        static let questions = "questions"
        static let userAnswers = "user_answers"
        static let finalScores = "final_scores"
        struct UserAnswer {
            static let selected_answer = "selected_answer"
            static let points = "points"
        }
    }
    
    // Lobby fields
    struct Lobby {
        static let quizId = "quiz_id"
        static let type = "type"
        static let players = "players"
        static let invitedUsers = "invited_users"
        static let invitedGroups = "invited_groups"
        static let joinCode = "join_code"
        static let competitive = "competitive"
    }
    
    // Group fields
    struct Group {
        static let name = "name"
        static let members = "members"
    }
}

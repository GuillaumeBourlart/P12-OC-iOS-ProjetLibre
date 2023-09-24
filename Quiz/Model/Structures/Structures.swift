//
//  QuestionResponseStruct.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import Foundation

// Struct for questions
struct UniversalQuestion: Decodable, Equatable {
    var id: String?
    let category: String?
    let type: String?
    let difficulty: String?
    let question: String
    let correct_answer: String
    let incorrect_answers: [String]
    let explanation: String?
    
    var dictionary: [String: Any] {
        return [
            FirestoreFields.Question.category: category as Any,
            FirestoreFields.Question.type: type as Any,
            FirestoreFields.Question.difficulty: difficulty as Any,
            FirestoreFields.Question.question: question,
            FirestoreFields.Question.correctAnswer: correct_answer,
            FirestoreFields.Question.incorrectAnswers: incorrect_answers,
            FirestoreFields.Question.explanation: explanation as Any
        ]
    }
    
    init(id: String? = nil, category: String?, type: String?, difficulty: String?, question: String, correct_answer: String, incorrect_answers: [String], explanation: String?) {
        self.id = id
        self.category = category
        self.type = type
        self.difficulty = difficulty
        self.question = question
        self.correct_answer = correct_answer
        self.incorrect_answers = incorrect_answers
        self.explanation = explanation
    }
}

// Struct for quiz
struct Quiz: Decodable, Equatable {
    var id: String
    var name: String
    var category_id: String
    var creator: String
    var difficulty: String
    var questions: [String: UniversalQuestion]
    var average_score: Int
    var users_completed: Int
    var code: String
}

// Struct for current user informations
struct CurrentUser: Decodable {
    let id: String
    let username: String
    let email: String
    let inscription_date: Date
    var rank: Int
    var points: Int
    var invites: [String: String]
    var profile_picture: String
    var friends: [String]
    var friendRequests: [String: FriendRequest]
    
    struct FriendRequest: Decodable, Equatable {
        let status: String
        let date: Date
    }
}

// Struct for groups
struct FriendGroup: Decodable {
    var id: String
    var creator: String
    var name: String
    var members: [String]
}

// Struct for game data
struct GameData: Decodable {
    var id: String
    let creator: String
    let competitive: Bool
    let status: String
    var players: [String]
    let date: Date
    let quiz_id: String?
    var questions: [String: UniversalQuestion]
    var user_answers: [String: [String: UserAnswer]]?
    var final_scores: [String: Int]?
}

// Struct for user answer
struct UserAnswer: Decodable {
    let selected_answer: String
    let points: Int
    
    var dictionary: [String: Any] {
        return [
            FirestoreFields.Game.UserAnswer.selected_answer: selected_answer,
            FirestoreFields.Game.UserAnswer.points: points
        ]
    }
}

// Struct for lobby
struct Lobby: Decodable {
    let id: String
    let creator: String
    let quiz_id: String
    let type: String
    let status: String
    var players: [String]
    var invited_users: [String]
    var invited_groups: [String]
    let join_code: String
}

// Struct of json response from deepl
struct DeepLResponse: Codable {
    let translations: [Translation]
}
struct Translation: Codable {
    let text: String
}

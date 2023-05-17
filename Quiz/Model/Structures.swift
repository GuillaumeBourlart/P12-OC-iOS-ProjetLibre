//
//  QuestionResponseStruct.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import Foundation

struct UniversalQuestion: Decodable, Equatable {
    var id: String?
    let category: String?
    let type: String?
    let difficulty: String?
    let question: String
    let correct_answer: String
    let incorrect_answers: [String]
    let explanation: String?
    
    // Conversion en dictionnaire
    var dictionary: [String: Any] {
        return [
            
            "category": category as Any,
            "type": type as Any,
            "difficulty": difficulty as Any,
            "question": question,
            "correct_answer": correct_answer,
            "incorrect_answers": incorrect_answers,
            "explanation": explanation as Any
        ]
    }
    
    // Initializer pour les données directes
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



struct Quiz: Decodable, Equatable {
    var id: String?
    var name: String
    var category_id: String
    var creator: String
    var difficulty: String
    var questions: [UniversalQuestion]
    var average_score: Int
    var users_completed: Int
    var code: String
    
}


struct User: Decodable {
    let username: String
    let email: String
    let first_name: String
    let last_name: String
    let birth_date: Date
    let inscription_date: Date
    let rank: Int
    let points: Int
    let profile_picture: String
    var friends: [String]
    var friend_groups: [String]
    var games: [String]
    var created_quizzes: [String]
    var friendRequests: [String: FriendRequest]
    
    struct FriendRequest: Decodable {
        let status: String
        let date: Date
    }
}


struct FriendGroup: Decodable {
    var id: String?
    var name: String
    var members: [String]
}




struct GameData: Decodable {
    var id: String?
    let name: String
    let creator: String
    let competitive: Bool
    let status: String
    let players: [String]
    let date: Date
    let quiz: String?
    var questions: [String: UniversalQuestion]
    var user_answers: [String: [String: UserAnswer]]
}

struct UserAnswer: Decodable {
    let id: String?
    let selected_answer: String
    let points: Int
    
    var dictionary: [String: Any] {
        return [
            "selected_answer": selected_answer,
            "points": points
        ]
    }
}


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



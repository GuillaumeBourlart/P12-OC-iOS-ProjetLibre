//
//  File.swift
//  QuizTests
//
//  Created by Guillaume Bourlart on 18/05/2023.
//

import Foundation


class fakeResponsesData {
    
    //-----------------------------------------------------------------------------------
    //                                 GAMES
    //-----------------------------------------------------------------------------------
    
    static let mockGameData: [String: Any] = [
        "name": "Quizz entre amis",
        "creator": "user1",
        "competitive": true,
        "status": "completed",
        "players": ["user_id_1", "user_id_2"],
        "quiz_id": "quiz_id_1",
        "date": Date(),
        "questions": [
            "question_id_1": [
                "category": "History",
                "type": "multiple",
                "difficulty": "easy",
                "question": "What was William Frederick Cody better known as?",
                "correct_answer": "Buffalo Bill",
                "incorrect_answers": ["Billy the Kid", "Wild Bill Hickok", "Pawnee Bill"]
            ],
            "question_id_2": [
                "category": "Geography",
                "type": "multiple",
                "difficulty": "easy",
                "question": "What's the capital of France?",
                "correct_answer": "Paris",
                "incorrect_answers": ["gvfc", "fevcd", "vede"]
            ]
        ],
        "user_answers": [
            "user_id_1": [
                "question_id_1": [
                    "selected_answer": "A",
                    "points": 10
                ],
                "question_id_2": [
                    "selected_answer": "A",
                    "points": 10
                ]
            ],
            "user_id_2": [
                "question_id_1": [
                    "selected_answer": "A",
                    "points": 10
                ],
                "question_id_2": [
                    "selected_answer": "A",
                    "points": 10
                ]
            ]
        ]
    ]
    
    static let mockGamesData: [[String: Any]] = [mockGameData, mockGameData, mockGameData]
    
    //-----------------------------------------------------------------------------------
    //                                 USERS
    //-----------------------------------------------------------------------------------
    
    static let mockUserData: [String: Any] = [
        "username": "user1",
        "email": "user1@email.com",
        "first_name": "username",
        "last_name": "lastname",
        "birth_date": "12/09/1097",
        "inscription_date": "12/09/1097",
        "rank": 1,
        "points": 0,
        "profile_picture": "https://example.com/user1/profile_picture.jpg",
        "friends": ["userID_2", "userID_3"],
        "friend_groups": ["group_id_1"],
        "games": ["game_id_1", "game_id_2"],
        "created_quizzes": ["quiz_id_1", "quiz_id_2"],
        "friendRequests": ["user_id_2": ["status": "sent", "date": "2023-04-12T12:00:00"]]
    ]
    static let mockUsersData: [[String: Any]] = [mockUserData, mockUserData, mockUserData]
    
    //-----------------------------------------------------------------------------------
    //                                 QUIZZES
    //-----------------------------------------------------------------------------------
    
    static let mockQuizData: [String: Any] = [
        "name": "Histoire - Seconde Guerre mondiale",
        "category_id": "category_id_1",
        "creator": "user_id_1",
        "difficulty": "Facile",
        "average_score": 0,
        "users_completed": 0,
        "code": "68HVN",
        "questions": [
            "question_id_1": [
                "question": "Quelle année marque le début de la Seconde Guerre mondiale?",
                "wrong_answers": ["1939","1940","1938"],
                "correct_answer": "1937",
                "explanation": "La Seconde Guerre mondiale a débuté en 1939 avec l'invasion de la Pologne par l'Allemagne."
            ]
        ]
    ]
    
    static let mockQuizzesData: [[String: Any]] = [mockQuizData, mockQuizData, mockQuizData]
    
    //-----------------------------------------------------------------------------------
    //                                 LOBBIES
    //-----------------------------------------------------------------------------------
    
    static let testLobbyData: [String: Any] = [
        "creator": "user_id_1",
        "id": "testLobbyID",
        "status": "waiting",
        "competitive": true
    ]
    
    static let testLobbiesData: [[String: Any]] = [testLobbyData, testLobbyData, testLobbyData]
    
    
    //-----------------------------------------------------------------------------------
    //                                 GROUPS
    //-----------------------------------------------------------------------------------
    
    static let mockGroupData: [String: Any] = [
        "name": "Groupe d'amis",
        "members": ["user_id_1", "user_id_2"]
    ]
    static let mockQGroupsData: [[String: Any]] = [mockGroupData, mockGroupData, mockGroupData]
    
    
    static let mockQuestionsData = ["questions": [
        "question_id_1": [
            "category": "History",
            "type": "multiple",
            "difficulty": "easy",
            "question": "What was William Frederick Cody better known as?",
            "correct_answer": "Buffalo Bill",
            "incorrect_answers": ["Billy the Kid", "Wild Bill Hickok", "Pawnee Bill"]
        ],
        "question_id_2": [
            "category": "Geography",
            "type": "multiple",
            "difficulty": "easy",
            "question": "What's the capital of France?",
            "correct_answer": "Paris",
            "incorrect_answers": ["gvfc", "fevcd", "vede"]
        ]
    ]
    ]
    
    
    static let mockAnswersData = [
        "user_answers": [
            "user_id_1": [
                "question_id_1": [
                    "selected_answer": "A",
                    "points": 10
                ],
                "question_id_2": [
                    "selected_answer": "A",
                    "points": 10
                ]
            ],
            "user_id_2": [
                "question_id_1": [
                    "selected_answer": "A",
                    "points": 10
                ],
                "question_id_2": [
                    "selected_answer": "A",
                    "points": 10
                ]
            ]
        ]
    ]
    
}

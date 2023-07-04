//
//  File.swift
//  QuizTests
//
//  Created by Guillaume Bourlart on 18/05/2023.
//

import XCTest
@testable import Quiz

class fakeResponsesData {
    
    //-----------------------------------------------------------------------------------
    //                                 GAMES
    //-----------------------------------------------------------------------------------
    
    
    
    static let mockGameData: [String: Any] = [
        "id": "quizid",
        "creator": "user1",
        "competitive": true,
        "status": "waiting",
        "players": ["user_id_1", "user_id_2"],
        "quiz_id": "quiz_id_1",
        "date": "2023-05-22T14:53:27Z",
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
        "id": "id",
        "username": "username",
        "email": "user1@email.com",
        "first_name": "username",
        "last_name": "lastname",
        "birth_date": "2023-05-22T14:53:27Z",
        "inscription_date": "2023-05-22T14:53:27Z",
        "rank": 1,
        "points": 0,
        "profile_picture": "https://example.com/user1/profile_picture.jpg",
        "friends": ["userID_2", "userID_3"],
        "invites": ["userid1": "lobbyid1", "userid2": "lobbyid2"],
        "friendRequests": ["user_id_2": ["status": "sent", "date": "2023-05-22T14:53:27Z"]]
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
        "code": "68HVN",
        "questions": [
            "question_id_1": [
                "question": "Quelle année marque le début de la Seconde Guerre mondiale?",
                "incorrect_answers": ["1939","1940","1938"],
                "correct_answer": "1937",
                "explanation": "La Seconde Guerre mondiale a débuté en 1939 avec l'invasion de la Pologne par l'Allemagne.",
                "category": "rfvcer",
                "difficulty": "gvfc",
                "type": "gh",
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
        "competitive": true,
        "players": ["user2", "user3"],
        "invited_users": [],
        "invited_groups": ["group1", "group2"],
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

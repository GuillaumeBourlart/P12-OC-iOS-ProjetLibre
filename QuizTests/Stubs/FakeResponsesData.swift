//
//  File.swift
//  QuizTests
//
//  Created by Guillaume Bourlart on 18/05/2023.
//

import Foundation


class fakeResponsesData {
    
    
    
    static let mockGameData: [String: Any] = [
        "name": "Quizz entre amis",
        "creator": "user1",
        "competitive": true,
        "status": "completed",
        "players": ["user_id_1", "user_id_2"],
        "quiz_id": "quiz_id_1",
        "date": "2023-04-12T12:00:00",
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
}

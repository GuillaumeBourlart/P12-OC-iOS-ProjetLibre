//
//  GameTests.swift
//  QuizTests
//
//  Created by Guillaume Bourlart on 18/05/2023.
//
@testable import Quiz
import XCTest
import Firebase

final class GameTests: XCTestCase {
    
    var firebaseUser: FirebaseUser!
    var networkRequestStub: NetworkRequestStub!
    var service: Service!
    
        var game: Game!
        var firebaseServiceStub: FirebaseServiceStub!
        
        override func setUp() {
            super.setUp()
            networkRequestStub = NetworkRequestStub()
            firebaseServiceStub = FirebaseServiceStub()
            game = Game(firebaseService: firebaseServiceStub)
            game.apiManager = OpenTriviaDatabaseManager(service: Service(networkRequest: networkRequestStub))
        }
    
    
    
    override func tearDown() {
            game = nil
            firebaseServiceStub.stubbedDocumentError = nil
        firebaseServiceStub.stubbedDocumentSnapshots = nil
        firebaseServiceStub.stubbedQuerySnapshotDatas = nil
        firebaseServiceStub.stubbedListenerData = nil
            firebaseServiceStub = nil
            super.tearDown()
        }
    
    //-----------------------------------------------------------------------------------
    //                                 COMPETITIVE
    //-----------------------------------------------------------------------------------
        
        func testSearchCompetitiveRoom_lobbyFound_Success() {
            firebaseServiceStub.stubbedQuerySnapshotDatas = [fakeResponsesData.testLobbiesData]
            firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.testLobbyData]
            
            let jsonData = "{\"results\": [{\"category\": \"category1\", \"type\": \"multiple\", \"difficulty\": \"easy\", \"question\": \"What is the capital of France?\", \"correct_answer\": \"Paris\", \"incorrect_answers\": [\"London\", \"Berlin\", \"Madrid\"]}]}".data(using: .utf8)
            networkRequestStub.data = jsonData
            
            let expectation = self.expectation(description: "Search competitive room succeeds")
            game.searchCompetitiveRoom { result in
                switch result {
                case .success(let lobbyId):
                    XCTAssertNotNil(lobbyId)
                case .failure(let error):
                    XCTFail("Expected success, got \(error) instead")
                }
                expectation.fulfill()
            }
            waitForExpectations(timeout: 1)
        }
    
    func testSearchCompetitiveRoo_NoLobbyFound_Success() {
        firebaseServiceStub.stubbedQuerySnapshotDatas = []
        
        
        let expectation = self.expectation(description: "Search competitive room succeeds")
        game.searchCompetitiveRoom { result in
            switch result {
            case .success(let lobbyId):
                XCTAssertNotNil(lobbyId)
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

        func testSearchCompetitiveRoom_Failure() {
            firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

            let expectation = self.expectation(description: "Search competitive room fails")
            game.searchCompetitiveRoom { result in
                switch result {
                case .success(let lobbyId):
                    XCTFail("Expected failure, got \(lobbyId) instead")
                    expectation.fulfill()
                case .failure(_):
                    expectation.fulfill()
                }
            }
            waitForExpectations(timeout: 1)
        }

    func testJoinCompetitiveRoom_Success() {
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.testLobbyData]

            let expectation = self.expectation(description: "Join competitive room succeeds")
            game.joinCompetitiveRoom(lobbyId: "lobby1") { result in
                switch result {
                case .success():
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Expected success, got \(error) instead")
                }
            }
            waitForExpectations(timeout: 1)
        }

        func testJoinCompetitiveRoom_Failure() {
            firebaseServiceStub.userID = "user1"
            firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

            let expectation = self.expectation(description: "Join competitive room fails")
            game.joinCompetitiveRoom(lobbyId: "lobby1") { result in
                switch result {
                case .success():
                    XCTFail("Expected failure, but got success instead")
                case .failure(_):
                    expectation.fulfill()
                }
            }
            waitForExpectations(timeout: 1)
        }

        func testCreateCompetitiveRoom_Success() {
            firebaseServiceStub.userID = "user1"

            let expectation = self.expectation(description: "Create competitive room succeeds")
            game.createCompetitiveRoom { result in
                switch result {
                case .success(let lobbyId):
                    XCTAssertEqual(lobbyId.count, 36)  // UUID is 36 characters long
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Expected success, got \(error) instead")
                }
            }
            waitForExpectations(timeout: 1)
        }

        func testCreateCompetitiveRoom_Failure() {
            firebaseServiceStub.userID = "user1"
            firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

            let expectation = self.expectation(description: "Create competitive room fails")
            game.createCompetitiveRoom { result in
                switch result {
                case .success(let lobbyId):
                    XCTFail("Expected failure, got \(lobbyId) instead")
                case .failure(_):
                    expectation.fulfill()
                }
            }
            waitForExpectations(timeout: 1)
        }

        // Pour ce test, assurez-vous d'avoir un échantillon de données de questions qui correspondent à ce que votre service renverrait
        func testGetQuestionsInQuiz_Success() {
            firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockQuizData]

            let expectation = self.expectation(description: "Get questions succeeds")
            game.getQuestions(quizId: "quiz1", gameId: nil) { result in
                switch result {
                case .success(let questions):
                    XCTAssertNotNil(questions)
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Expected success, got \(error) instead")
                }
            }
            waitForExpectations(timeout: 1)
        }
    
    func testGetQuestionsInQuiz_failed() {
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

        let expectation = self.expectation(description: "Get questions succeeds")
        game.getQuestions(quizId: "quiz1", gameId: nil) { result in
            switch result {
            case .success(let questions):
                XCTFail("Expected error, got success")
                
            case .failure(let error):
                
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    func testGetQuestionsInGame_Success() {
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockGameData]

        let expectation = self.expectation(description: "Get questions succeeds")
        game.getQuestions(quizId: nil, gameId: "game1") { result in
            switch result {
            case .success(let questions):
                XCTAssertNotNil(questions)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    func testGetQuestionsInGame_failed() {
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

        let expectation = self.expectation(description: "Get questions succeeds")
        game.getQuestions(quizId: nil, gameId: "game1") { result in
            switch result {
            case .success(let questions):
                XCTFail("Expected success, got success instead")
                
            case .failure(let error):
                
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    
    
    //-----------------------------------------------------------------------------------
    //                                 QUICK PLAY
    //-----------------------------------------------------------------------------------
    
    // Test for createRoom

        func testCreateRoom_Success() {
            let expectation = self.expectation(description: "Create room succeeds")
            firebaseServiceStub.stubbedQuerySnapshotDatas = []
            
            game.createRoom(quizID: "quiz1") { result in
                switch result {
                case .success(let lobbyId):
                    XCTAssertNotNil(lobbyId)  // UUID is 36 characters long
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Expected success, got \(error) instead")
                }
            }
            waitForExpectations(timeout: 1)
        }

//        func testCreateRoom_Failure() {
//            firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
//
//            let expectation = self.expectation(description: "Create room fails")
//
//            game.createRoom(quizID: "quiz1") { result in
//                switch result {
//                case .success(let lobbyId):
//                    XCTFail("Expected failure, got \(lobbyId) instead")
//                case .failure(let error):
//                    XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
//                    expectation.fulfill()
//                }
//            }
//            waitForExpectations(timeout: 1)
//        }

        // Test for invitePlayerInRoom

        func testInvitePlayerInRoom_Success() {
            firebaseServiceStub.userID = "user1"
            let expectation = self.expectation(description: "Invite player succeeds")
            
            game.invitePlayerInRoom(lobbyId: "lobby1", invited_players: ["player1"], invited_groups: ["group1"]) { result in
                switch result {
                case .success:
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Expected success, got \(error) instead")
                }
            }
            waitForExpectations(timeout: 1)
        }

        func testInvitePlayerInRoom_Failure() {
            firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

            let expectation = self.expectation(description: "Invite player fails")

            game.invitePlayerInRoom(lobbyId: "lobby1", invited_players: ["player1"], invited_groups: ["group1"]) { result in
                switch result {
                case .success:
                    XCTFail("Expected failure, got success instead")
                case .failure(let error):
                    XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                    expectation.fulfill()
                }
            }
            waitForExpectations(timeout: 1)
        }
    
    // Test for deleteCurrentRoom

        func testDeleteCurrentRoom_Success() {
            let expectation = self.expectation(description: "Delete room succeeds")

            game.deleteCurrentRoom(lobbyId: "lobby1") { result in
                switch result {
                case .success:
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Expected success, got \(error) instead")
                }
            }
            waitForExpectations(timeout: 1)
        }

        func testDeleteCurrentRoom_Failure() {
            firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

            let expectation = self.expectation(description: "Delete room fails")

            game.deleteCurrentRoom(lobbyId: "lobby1") { result in
                switch result {
                case .success:
                    XCTFail("Expected failure, got success instead")
                case .failure(let error):
                    XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                    expectation.fulfill()
                }
            }
            waitForExpectations(timeout: 1)
        }

        // Test for joinRoom

        // Here, as the function involves getting and updating data, you might want to
        // add more tests to check the logic inside the function.

    func testJoinRoom_Success() {
        let expectation = self.expectation(description: "Join room succeeds")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.testLobbyData, fakeResponsesData.mockUserData]
        
        game.joinRoom(lobbyId: "lobby1") { result in
            switch result {
            case .success:
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
        }
        waitForExpectations(timeout: 1)
    }

        func testJoinRoom_Failure() {
            firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.testLobbyData]
            firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

            let expectation = self.expectation(description: "Join room fails")

            game.joinRoom(lobbyId: "lobby1") { result in
                switch result {
                case .success:
                    XCTFail("Expected failure, got success instead")
                case .failure(let error):
                    XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                    expectation.fulfill()
                }
            }
            waitForExpectations(timeout: 1)
        }
    
    
    //-----------------------------------------------------------------------------------
    //                                 GENERAL
    //-----------------------------------------------------------------------------------
    
    // Test for createQuestionsForGame

    func testCreateQuestionsForGameFromQuiz_Success() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockQuizData]

        game.createQuestionsForGame(quizId: "quiz1", category: nil, difficulty: nil, with: "doc1", competitive: true, players: ["player1", "player2"]) { result in
            switch result {
            case .failure(let error):
                XCTFail("Expected to success, got failure instead")
            case .success(let data):
                XCTAssertNotNil(data)
                expectation.fulfill()
            }
            
        }
        waitForExpectations(timeout: 2.0, handler: nil)

    }
    
//    func testCreateQuestionsForGameFromTriviaDB_Success() {
//        let expectation = self.expectation(description: "Completion handler invoked")
//        
//        let jsonData = "{\"results\": [{\"category\": \"category1\", \"type\": \"multiple\", \"difficulty\": \"easy\", \"question\": \"What is the capital of France?\", \"correct_answer\": \"Paris\", \"incorrect_answers\": [\"London\", \"Berlin\", \"Madrid\"]}]}".data(using: .utf8)
//        networkRequestStub.data = jsonData
//
//        game.createQuestionsForGame(quizId: nil, category: 1, difficulty: "easy", with: "doc1", competitive: true, players: ["player1", "player2"]) { result in
//            switch result {
//            case .failure(let error):
//                XCTFail("Expected to success, got failure instead")
//            case .success(let data):
//                XCTAssertNotNil(data)
//                expectation.fulfill()
//            }
//        }
//
//        waitForExpectations(timeout: 2.0, handler: nil)
//    }

    func testCreateQuestionsForGame_Failure() {
        firebaseServiceStub.userID = "user1"
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

        game.createQuestionsForGame(quizId: "quiz1", category: 1, difficulty: "easy", with: "doc1", competitive: true, players: ["player1", "player2"]) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got success instead")
            case .failure(let error):
                XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // Test for createGame

    func testCreateGame_Success() {
        firebaseServiceStub.userID = "user1"
        let expectation = self.expectation(description: "Completion handler invoked")

        let question = UniversalQuestion(id: "id1", category: "cat1", type: "type1", difficulty: "easy", question: "question1", correct_answer: "answer1", incorrect_answers: ["wrong1", "wrong2", "wrong3"], explanation: "")
        
        game.createGame(questions: [question], with: "doc1", competitive: true, players: ["player1", "player2"]) { result in
            switch result {
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            case .success(let data):
                XCTAssertNotNil(data)
                expectation.fulfill()
            }
    
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testCreateGame_Failure() {
        firebaseServiceStub.userID = "user1"
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

        let question = UniversalQuestion(id: "id1", category: "cat1", type: "type1", difficulty: "easy", question: "question1", correct_answer: "answer1", incorrect_answers: ["wrong1", "wrong2", "wrong3"], explanation: "")
        
        game.createGame(questions: [question], with: "doc1", competitive: true, players: ["player1", "player2"]) { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(let data):
                XCTFail("Expected error, got success instead")
                
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // Test for leaveGame

    func testLeaveGame_Success() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockGameData]

        game.leaveGame(gameId: "game1") { result in
            switch result {
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            case .success(let data):
                XCTAssertNotNil(data)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testLeaveGame_Failure() {
        firebaseServiceStub.userID = "user1"
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

        game.leaveGame(gameId: "game1") { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(let data):
                XCTFail("Expected error, got success instead")
                
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)

    }
    
    //-----------------------------------------------------------------------------------
    //                                GAME DATA
    //-----------------------------------------------------------------------------------
    
    // Test for checkIfGameExist

    func testCheckIfGameExist_Success() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockGameData]

        game.checkIfGameExist(gameID: "game1") { result in
            switch result {
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            case .success(let data):
                XCTAssertNotNil(data)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testCheckIfGameExist_Failure() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

        game.checkIfGameExist(gameID: "game1") { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(let data):
                XCTFail("Expected error, got success instead")
                
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)    }
    
    // Test for getCompletedGames

    func testGetCompletedGames_Success() {
        firebaseServiceStub.userID = "user1"
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedQuerySnapshotDatas = [fakeResponsesData.mockGamesData]

        game.getCompletedGames { result in
            switch result {
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            case .success(let data):
                XCTAssertNotNil(data)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testGetCompletedGames_Failure() {
        firebaseServiceStub.userID = "user1"
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

        game.getCompletedGames { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(let data):
                XCTFail("Expected error, got success instead")
                
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // Test for getGameData

    func testGetGameData_Success() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockGameData]

        game.getGameData(gameId: "game1") { result in
            switch result {
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            case .success(let data):
                XCTAssertNotNil(data)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testGetGameData_Failure() {
        firebaseServiceStub.userID = "user1"
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

        game.getGameData(gameId: "game1") { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(let data):
                XCTFail("Expected error, got success instead")
                
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // Test for saveStats

    func testSaveStats_Success() {
        let expectation = self.expectation(description: "Completion handler invoked")
        let userAnswers: [String: UserAnswer] = ["answer1": UserAnswer(selected_answer: "question1", points: 27)]

        game.saveStats(finalScore: 100, userAnswers: userAnswers, gameID: "game1") { result in
            switch result {
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            case .success(let data):
                XCTAssertNotNil(data)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testSaveStats_Failure() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        let userAnswers: [String: UserAnswer] = ["answer1": UserAnswer(selected_answer: "question1", points: 32)]

        game.saveStats(finalScore: 100, userAnswers: userAnswers, gameID: "game1") { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(let data):
                XCTFail("Expected error, got success instead")
                
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // Test for ListenForChangeInDocument

    func testListenForChangeInDocument_Success() {
        let expectation = self.expectation(description: "Completion handler invoked")

        let listener = game.ListenForChangeInDocument(in: "collection1", documentId: "doc1") { result in
            switch result {
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            case .success(let data):
                XCTAssertNotNil(data)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
        listener.remove() // Remove the listener after testing
    }

    func testListenForChangeInDocument_Failure() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

        let listener = game.ListenForChangeInDocument(in: "collection1", documentId: "doc1") { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as? NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(let data):
                XCTFail("Expected error, got success instead")
                
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
        listener.remove() // Remove the listener after testing
    }
    
    
    // Test for convertTimestampsToDate
    func testConvertTimestampsToDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = Date()
        let timestamp = Timestamp(date: date)
        let nestedTimestamp = Timestamp(date: date.addingTimeInterval(60))

        let data: [String: Any] = [
            "key1": "value1",
            "key2": timestamp,
            "key3": [
                "nestedKey1": "nestedValue1",
                "nestedKey2": nestedTimestamp
            ]
        ]

        let convertedData = game.convertTimestampsToDate(in: data)

        XCTAssert(convertedData["key1"] as? String == "value1")
        XCTAssert(convertedData["key2"] as? String == dateFormatter.string(from: date))

        if let nestedData = convertedData["key3"] as? [String: Any] {
            XCTAssert(nestedData["nestedKey1"] as? String == "nestedValue1")
            XCTAssert(nestedData["nestedKey2"] as? String == dateFormatter.string(from: date.addingTimeInterval(60)))
        } else {
            XCTFail("Failed to convert nested data")
        }
    }
        
        
    }


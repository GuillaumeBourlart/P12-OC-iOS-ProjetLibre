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
    
    var networkRequestStub: NetworkRequestStub!
    var translatorNetworkRequestStub: NetworkRequestStub!
    var service: Service!
    
    var game: Game!
    var firebaseServiceStub: FirebaseServiceStub!
    
    override func setUp() {
        super.setUp()
        networkRequestStub = NetworkRequestStub()
        translatorNetworkRequestStub = NetworkRequestStub()
        firebaseServiceStub = FirebaseServiceStub()
        game = Game(apiManager: OpenTriviaDatabaseManager(service: Service(networkRequest: networkRequestStub), translatorService: Service(networkRequest: translatorNetworkRequestStub)), firebaseService: firebaseServiceStub)
    }
    
    
    override func tearDown() {
        game = nil
        
        firebaseServiceStub.stubbedDocumentError = nil
        firebaseServiceStub.stubbedDocumentSnapshots = nil
        firebaseServiceStub.stubbedQuerySnapshotDatas = nil
        firebaseServiceStub.stubbedListenerData = nil
        firebaseServiceStub = nil
        
        networkRequestStub.dataQueue = nil
        networkRequestStub.error = nil
        networkRequestStub = nil
        
        super.tearDown()
    }
    
    //-----------------------------------------------------------------------------------
    //                                 COMPETITIVE
    //-----------------------------------------------------------------------------------
    
    // Search competitive rom
    
    func testGivenValidData_WhenSearchingCompetitiveRoomAndFindOne_ThenReturnsLobbyId() {
        firebaseServiceStub.stubbedQuerySnapshotDatas = [fakeResponsesData.testLobbiesData]
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.testLobbyData]
        
        guard let jsonData = "{\"results\": [{\"category\": \"category1\", \"type\": \"multiple\", \"difficulty\": \"easy\", \"question\": \"What is the capital of France?\", \"correct_answer\": \"Paris\", \"incorrect_answers\": [\"London\", \"Berlin\", \"Madrid\"]}]}".data(using: .utf8) else {return}
        networkRequestStub.dataQueue = [jsonData]
        
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
    
    func testGivenValidData_WhenSearchingCompetitiveRoomAndDontFind_ThenReturnsLobbyId() {
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
    
    func testGivenErrorNotNil_WhenSearchingCompetitiveRoom_ThenReturnsFailure() {
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
    
    // join competitive room
    
    func testGivenValidData_WhenJoiningCompetitiveRoom_ThenReturnsSuccess() {
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.testLobbyData]
        
        guard let jsonData = "{\"results\": [{\"category\": \"category1\", \"type\": \"multiple\", \"difficulty\": \"easy\", \"question\": \"What is the capital of France?\", \"correct_answer\": \"Paris\", \"incorrect_answers\": [\"London\", \"Berlin\", \"Madrid\"]}]}".data(using: .utf8) else {return}
        networkRequestStub.dataQueue = [jsonData]
        
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
    
    func testGivenError_WhenJoiningCompetitiveRoom_ThenReturnsFailure() {
        
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
    
    // create competitive room
    
    func testGivenNoError_WhenCreatingCompetitiveRoom_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenCreatingCompetitiveRoom_ThenReturnsFailure() {
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
    
    // get question from a quiz
    
    func testGivenNoError_WhenGettingQuestionFromQuiz_ThenReturnsSuccess() {
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockQuizData]
        
        let expectation = self.expectation(description: "Get questions succeeds")
        game.getQuestions(quizId: "quiz1", gameId: nil) { result in
            switch result {
            case .success(let questions):
                XCTAssertEqual(questions.count, 1)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    func testGivenError_WhenGettingQuestionFromQuiz_ThenReturnsFailure() {
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let expectation = self.expectation(description: "Get questions succeeds")
        game.getQuestions(quizId: "quiz1", gameId: nil) { result in
            switch result {
            case .success:
                XCTFail("Expected error, got success")
                
            case .failure:
                
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    func testGivenEmptyResponse_WhenGettingQuestionFromQuiz_ThenReturnsFailure() {
        firebaseServiceStub.stubbedDocumentSnapshots = []
        
        let expectation = self.expectation(description: "Get questions succeeds")
        game.getQuestions(quizId: "quiz1", gameId: nil) { result in
            switch result {
            case .success:
                XCTFail("Expected error, got success")
                
            case .failure:
                
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    // get question from a game
    
    func testGivenNoError_WhenGettingQuestionFromGame_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenGettingQuestionFromGame_ThenReturnsFailure() {
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let expectation = self.expectation(description: "Get questions succeeds")
        game.getQuestions(quizId: nil, gameId: "game1") { result in
            switch result {
            case .success(_):
                XCTFail("Expected success, got success instead")
                
            case .failure(_):
                
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    
    
    //-----------------------------------------------------------------------------------
    //                                 QUICK PLAY
    //-----------------------------------------------------------------------------------
    
    // Test for createRoom
    
    func testGivenEmptyData_WhenCreateRoom_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenCreateRoom_ThenReturnsFailure() {
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let expectation = self.expectation(description: "Create room fails")
        
        game.createRoom(quizID: "quiz1") { result in
            switch result {
            case .success(let lobbyId):
                XCTFail("Expected failure, got \(lobbyId) instead")
            case .failure(let error):
                XCTAssertEqual(error as NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    // Test for invitePlayerInRoom
    
    func testGivenNoerror_WhenInvitePlayers_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenInvitePlayers_ThenReturnsSuccess() {
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let expectation = self.expectation(description: "Invite player fails")
        
        game.invitePlayerInRoom(lobbyId: "lobby1", invited_players: ["player1"], invited_groups: ["group1"]) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got success instead")
            case .failure(let error):
                XCTAssertEqual(error as NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    // test join with code
    
    func testGivenValideData_WhenJoinWithCode_ThenReturnsSuccess() {
        // Stub the fake lobby data
        firebaseServiceStub.stubbedQuerySnapshotDatas = [fakeResponsesData.testLobbiesData]
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.testLobbyData, fakeResponsesData.mockUserData]
        
        let expectation = self.expectation(description: "Joining with code succeeds")
        game.joinWithCode(code: "TestCode") { result in
            switch result {
            case .success(let lobbyId):
                XCTAssertNotNil(lobbyId) // Replace "ExpectedLobbyId" with the id you expect
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testGivenEmptyData_WhenJoinWithCode_ThenReturnsFailure() {
        // Stub no lobby data
        firebaseServiceStub.stubbedQuerySnapshotDatas = []
        
        let expectation = self.expectation(description: "No lobby found for given code")
        game.joinWithCode(code: "TestCode") { result in
            switch result {
            case .success(let lobbyId):
                XCTFail("Expected failure, got \(lobbyId) instead")
            case .failure(let error):
                XCTAssertNotNil(error) // You could make this more specific if you expect a certain error
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testGivenError_WhenJoinWithCode_ThenReturnsFailure() {
        // Stub a network error
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let expectation = self.expectation(description: "Network error occurs while joining with code")
        game.joinWithCode(code: "TestCode") { result in
            switch result {
            case .success(let lobbyId):
                XCTFail("Expected failure, got \(lobbyId) instead")
            case .failure(let error):
                XCTAssertNotNil(error) // You could make this more specific if you expect a certain error
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    // Delete invite
    
    func testGivenValideData_WhenDeleteInvite_ThenReturnsSuccess() {
        let expectation = self.expectation(description: "Delete invite succeeds")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData]
        
        game.deleteInvite(inviteId: "inviteID") { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    func testGivenError_WhenDeleteInvite_ThenReturnsFailure() {
        let expectation = self.expectation(description: "Delete invite succeeds")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData]
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        game.deleteInvite(inviteId: "inviteID") { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got success instead")
            case .failure(_):
                
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    // Test for deleteCurrentRoom
    
    func testGivenNoError_WhenDeleteCurrentRoom_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenDeleteCurrentRoom_ThenReturnsFailure() {
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let expectation = self.expectation(description: "Delete room fails")
        
        game.deleteCurrentRoom(lobbyId: "lobby1") { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got success instead")
            case .failure(let error):
                XCTAssertEqual(error as NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    // Test for joinRoom
    
    
    func testGivenValideData_WhenJoiningRoom_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenJoiningRoom_ThenReturnsFailure() {
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.testLobbyData]
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let expectation = self.expectation(description: "Join room fails")
        
        game.joinRoom(lobbyId: "lobby1") { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got success instead")
            case .failure(let error):
                XCTAssertEqual(error as NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    // Leave lobby
    
    func testGivenValideData_WhenLeaveLobby_ThenReturnsSuccess() {
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.testLobbyData]
        
        let expectation = self.expectation(description: "Leave lobby succeeds")
        game.leaveLobby(lobbyId: "lobby1") { result in
            
            switch result {
            case .success():
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    func testGivenError_WhenLeaveLobby_ThenReturnsFailure() {
        let lobbyId = "lobby1"
        firebaseServiceStub.userID = "user1"
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let expectation = self.expectation(description: "Leave lobby fails")
        game.leaveLobby(lobbyId: lobbyId) { result in
            switch result {
            case .success():
                XCTFail("Expected failure, but got success instead")
            case .failure(_):
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    //-----------------------------------------------------------------------------------
    //                                 GENERAL
    //-----------------------------------------------------------------------------------
    
    // Test for createQuestionsForGame from a quiz
    
    func testGivenValideData_WhenCreateQuestionsForGameFromQuiz_ThenReturnsSuccess() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockQuizData]
        
        game.createQuestionsForGame(quizId: "quiz1", category: nil, difficulty: nil, with: "doc1", competitive: true, players: ["player1", "player2"]) { result in
            switch result {
            case .failure:
                XCTFail("Expected to success, got failure instead")
            case .success(let data):
                XCTAssertNotNil(data)
                expectation.fulfill()
            }
            
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testGivenError_WhenCreateQuestionsForGameFromQuiz_ThenReturnsFailure() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        game.createQuestionsForGame(quizId: "quiz1", category: 1, difficulty: "easy", with: "doc1", competitive: true, players: ["player1", "player2"]) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got success instead")
            case .failure(let error):
                XCTAssertEqual(error as NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // create question for a game from trivia DB
    
    func testGivenValideData_WhenCreateQuestionsForGameFromTriviaDB_ThenReturnsSuccess() {
        let expectation = self.expectation(description: "Completion handler invoked")
        
        guard let jsonData = "{\"results\": [{\"category\": \"category1\", \"type\": \"multiple\", \"difficulty\": \"easy\", \"question\": \"What is the capital of France?\", \"correct_answer\": \"Paris\", \"incorrect_answers\": [\"London\", \"Berlin\", \"Madrid\"]}]}".data(using: .utf8) else {print("error");return}
        networkRequestStub.dataQueue = [jsonData]
        game.createQuestionsForGame(quizId: nil, category: 1, difficulty: "easy", with: "doc1", competitive: true, players: ["player1", "player2"]) { result in
            switch result {
            case .failure:
                XCTFail("Expected to success, got failure instead")
            case .success(let data):
                XCTAssertNotNil(data)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testGivenError_WhenCreateQuestionsForGameFromTriviaDB_ThenReturnsFailure() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        game.createQuestionsForGame(quizId: nil, category: 1, difficulty: "easy", with: "doc1", competitive: true, players: ["player1", "player2"]) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got success instead")
            case .failure(_):
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    
    // Test for createGame
    
    func testGivenValideData_WhenCreateGame_ThenReturnsSuccess() {
        
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
    
    func testGivenError_WhenCreateGame_ThenReturnsFailure() {
        
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let question = UniversalQuestion(id: "id1", category: "cat1", type: "type1", difficulty: "easy", question: "question1", correct_answer: "answer1", incorrect_answers: ["wrong1", "wrong2", "wrong3"], explanation: "")
        
        game.createGame(questions: [question], with: "doc1", competitive: true, players: ["player1", "player2"]) { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(_):
                XCTFail("Expected error, got success instead")
                
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // Test for leaveGame
    
    func testGivenValideData_WhenLeaveGame_ThenReturnsSuccess() {
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockGameData]
        
        let expectation = self.expectation(description: "Leave game succeeds")
        game.leaveGame(gameId: "gameId") { result in
            switch result {
            case .success():
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success, got \(error) instead")
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    func testGivenError_WhenLeaveGame_ThenReturnsFailure() {
        let gameId = "game1"
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let expectation = self.expectation(description: "Leave game fails")
        game.leaveGame(gameId: gameId) { result in
            switch result {
            case .success():
                XCTFail("Expected failure, but got success instead")
            case .failure(_):
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    //-----------------------------------------------------------------------------------
    //                                GAME DATA
    //-----------------------------------------------------------------------------------
    
    // Test for checkIfGameExist
    
    func testGivenValideData_WhenCheckIfGameExist_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenCheckIfGameExist_ThenReturnsFailure() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        game.checkIfGameExist(gameID: "game1") { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(_):
                XCTFail("Expected error, got success instead")
                
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)    }
    
    // Test for getCompletedGames
    
    func testGivenValideData_WhenGetCompletedGames_ThenReturnsSuccess() {
        
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
    
    func testGivenError_WhenGetCompletedGames_ThenReturnsFailure() {
        
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        game.getCompletedGames { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(_):
                XCTFail("Expected error, got success instead")
                
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // Test for getGameData
    
    func testGivenValideData_WhenGeGameData_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenGetGameData_ThenReturnsFailure() {
        
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        game.getGameData(gameId: "game1") { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(_):
                XCTFail("Expected error, got success instead")
                
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // Test for saveStats
    
    func testGivenValideData_WhenSaveStats_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenSaveStats_ThenReturnsFailure() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        let userAnswers: [String: UserAnswer] = ["answer1": UserAnswer(selected_answer: "question1", points: 32)]
        
        game.saveStats(finalScore: 100, userAnswers: userAnswers, gameID: "game1") { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(_):
                XCTFail("Expected error, got success instead")
                
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // Test for updateXP
    
    func testGivenValideData_WhenUpdateXP_ThenReturnsSuccess() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData, fakeResponsesData.mockUserData]
        
        game.updateXP() { result in
            switch result {
            case .failure(let error):
                print(error)
                XCTFail("Expected success, got failure instead")
            case .success(_):
                expectation.fulfill()
                
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testGivenError_WhenUpdateXP_ThenReturnsFailure() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData, fakeResponsesData.mockUserData]
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        game.updateXP() { result in
            switch result {
            case .failure(let error):
                print(error)
                expectation.fulfill()
                
            case .success(_):
                XCTFail("Expected failure, got success instead")
                
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    // Tests for listener
    
    func testGivenNoError_WhenListenForChangeInDocument_ThenReturnsSuccess() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedListenerData = fakeResponsesData.mockGameData
        
        
        let listener = game.ListenForChangeInDocument(in: "collection1", documentId: "doc1") { result in
            switch result {
            case .failure(_):
                XCTFail("Expected error, got success instead")
            case .success(_):
                expectation.fulfill()
                
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
        listener?.remove() // Remove the listener after testing
    }
    
    func testGivenError_WhenListenForChangeInDocument_ThenReturnsFailure() {
        let expectation = self.expectation(description: "Completion handler invoked")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        let listener = game.ListenForChangeInDocument(in: "collection1", documentId: "doc1") { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as NSError, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                expectation.fulfill()
            case .success(_):
                XCTFail("Expected error, got success instead")
                
            }
        }
        
        waitForExpectations(timeout: 2.0, handler: nil)
        listener?.remove() // Remove the listener after testing
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
            ] as [String : Any]
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


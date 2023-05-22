//
//  GameTests.swift
//  QuizTests
//
//  Created by Guillaume Bourlart on 18/05/2023.
//
@testable import Quiz
import XCTest
import Firebase
import FirebaseAuth
import FirebaseFirestore

final class GameTests: XCTestCase {
    
    var game: Game!
    var firebaseUser: FirebaseUser!
    var firestoreService: FirestoreServiceStub!
    var firebaseAuthService: FirebaseAuthServiceStub!
    var networkRequestStub: NetworkRequestStub!
    var service: Service!
    override func setUp() {
        super.setUp()
        firestoreService = FirestoreServiceStub()
        firebaseAuthService = FirebaseAuthServiceStub()
        game = Game(firestoreService: firestoreService, firebaseAuthService: firebaseAuthService)
        firebaseUser = FirebaseUser(firestoreService: firestoreService, firebaseAuthService: firebaseAuthService)
    }
    
    override func tearDown() {
        game = nil
        firestoreService = nil
        firebaseAuthService = nil
        super.tearDown()
    }
    
    
    //-----------------------------------------------------------------------------------
    //                                 Search Competitive Lobby
    //-----------------------------------------------------------------------------------
    
    func testSearchCompetitiveLobby_noUserConnected() {
        let expectation = XCTestExpectation(description: "No user connected")
        
        game.searchCompetitiveLobby { result in
            if case .failure(let error) = result, error is MyError {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSearchCompetitiveLobby_noLobbyFound() {
        firebaseAuthService.userID = "TestUserId"
        firestoreService.stubbedQuerySnapshotData = []
        
        let expectation = XCTestExpectation(description: "New lobby created")
        
        game.searchCompetitiveLobby { result in
            if case .success = result {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSearchCompetitiveLobby_LobbyFound() {
        firebaseAuthService.userID = "TestUserId"
        firestoreService.stubbedQuerySnapshotData = fakeResponsesData.testLobbiesData
        
        networkRequestStub = NetworkRequestStub()
        service = Service(networkRequest: networkRequestStub)
        game.apiManager = OpenTriviaDatabaseManager(service: service)
        
        let expectation = XCTestExpectation(description: "New lobby created")
        
        game.searchCompetitiveLobby { result in
            if case .success = result {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSearchCompetitiveLobby_getDocumentsError() {
        firebaseAuthService.userID = "TestUserId"
        firestoreService.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        
        let expectation = XCTestExpectation(description: "getDocuments error")
        
        game.searchCompetitiveLobby { result in
            if case .failure = result {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    //-----------------------------------------------------------------------------------
    //                                 Create Competitive Lobby
    //-----------------------------------------------------------------------------------

    func testCreateCompetitiveLobby_noUserConnected() {
        let expectation = XCTestExpectation(description: "No user connected")
        
        game.createCompetitiveLobby { result in
            if case .failure(let error) = result, error is MyError {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func testCreateCompetitiveLobby_success() {
        firebaseAuthService.userID = "TestUserId"
        
        let expectation = XCTestExpectation(description: "New lobby created")
        
        game.createCompetitiveLobby { result in
            if case .success = result {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func testCreateCompetitiveLobby_setDataError() {
        firebaseAuthService.userID = "TestUserId"
        firestoreService.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        
        let expectation = XCTestExpectation(description: "setData error")
        
        game.createCompetitiveLobby { result in
            if case .failure = result {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    //-----------------------------------------------------------------------------------
    //                                 Join Competitive Lobby
    //-----------------------------------------------------------------------------------

    func testJoinCompetitiveLobby_noUserConnected() {
        let expectation = XCTestExpectation(description: "No user connected")
        
        game.joinCompetitiveLobby(lobbyId: "TestLobbyId") { result in
            if case .failure(let error) = result, error is MyError {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func testJoinCompetitiveLobby_success() {
        // Définir l'ID utilisateur factice
        firebaseAuthService.userID = "TestUserId"
        
        // Configurer les données factices pour firestoreService.getDocument
        firestoreService.stubbedDocumentSnapshot = fakeResponsesData.testLobbyData

        // Configurer les données factices pour firestoreService.updateDocument
        firestoreService.stubbedDocumentError = nil

        // Définir un lobbyId factice
        let lobbyId = "TestLobbyId"
        
        // Définir un jeu factice à créer dans joinCompetitiveLobby
        let mockGameId = "mockGameId"

        // Configurer les données factices pour createGame
        networkRequestStub = NetworkRequestStub()
        service = Service(networkRequest: networkRequestStub)
        game.apiManager = OpenTriviaDatabaseManager(service: service)
        
        
        // Assurez-vous que fetchQuestions renvoie des données factices appropriées

        // Configurer les données factices pour firestoreService.deleteDocument
        // Assurez-vous que la suppression de document renvoie nil pour une opération réussie

        let expectation = XCTestExpectation(description: "Join lobby success")
        
        game.joinCompetitiveLobby(lobbyId: lobbyId) { result in
            if case .success = result {
                // Vérifiez si le lobbyId actuel a été défini correctement
                XCTAssertEqual(self.game.currentLobbyId, lobbyId)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func testJoinCompetitiveLobby_getDocumentError() {
        firebaseAuthService.userID = "TestUserId"
        firestoreService.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        
        let expectation = XCTestExpectation(description: "getDocument error")
        
        game.joinCompetitiveLobby(lobbyId: "TestLobbyId") { result in
            if case .failure = result {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    //-----------------------------------------------------------------------------------
    //                                 CANCEL
    //-----------------------------------------------------------------------------------
    
    func testCancelSearch_noUserConnected() {
        firebaseAuthService.userID = nil
        
        let expectation = XCTestExpectation(description: "Completion handler invoked")
        var result: Result<Void, Error>?
        game.deleteCurrentLobby() { res in
            result = res
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        switch result {
        case .failure(let error as MyError):
            XCTAssertEqual(error, .noUserConnected)
        default:
            XCTFail("Expected '.failure(.noUserConnected)', but got \(String(describing: result))")
        }
    }
    
    func testCancelSearch_noActiveLobby() {
        firebaseAuthService.userID = "TestUserId"
        game.currentLobbyId = nil
        
        game.deleteCurrentLobby() { _ in
            XCTFail("Expected no call to completion handler, but it was called.")
        }
    }
    
    
    
    func testCancelSearch_success() {
        firebaseAuthService.userID = "TestUserId"
        game.currentLobbyId = "TestLobbyId"
        firestoreService.stubbedDocumentError = nil
        
        let expectation = XCTestExpectation(description: "Completion handler invoked")
        var result: Result<Void, Error>?
        game.deleteCurrentLobby() { res in
            result = res
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        switch result {
        case .success:
            XCTAssertNil(game.currentLobbyId)
        default:
            XCTFail("Expected '.success', but got \(String(describing: result))")
        }
    }
    
    func testCancelSearch_deleteDocumentFails() {
        firebaseAuthService.userID = "TestUserId"
        game.currentLobbyId = "TestLobbyId"
        let testError = NSError(domain: "Test", code: 1, userInfo: nil)
        firestoreService.stubbedDocumentError = testError
        
        let expectation = XCTestExpectation(description: "Completion handler invoked")
        var error: Error?
        game.deleteCurrentLobby() { result in
            if case .failure(let err) = result {
                error = err
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNotNil(error)
        XCTAssertEqual((error as NSError?)?.domain, testError.domain)
        XCTAssertEqual((error as NSError?)?.code, testError.code)
    }
    
    //-----------------------------------------------------------------------------------
    //                                 GET QUESTIONS
    //-----------------------------------------------------------------------------------
    
    func testGetQuestions_success() {
        // Initialisation de l'environnement de test
        firebaseAuthService.userID = "TestUserId"
        var gameId = "testGameId"
        
        firestoreService.stubbedDocumentSnapshot = fakeResponsesData.mockGameData
        
        game.getQuestions(gameId: gameId) { result in
            if case .success(let questions) = result {
                XCTAssertNotNil(questions)
            }
        }
        
    }
    
    func testGetQuestions_noUserConnected() {
        // Initialisation de l'environnement de test
        firebaseAuthService.userID = nil
        let gameId = "TestId"
        
        // Création de l'expectation
        let expectation = XCTestExpectation(description: "Completion handler invoked")
        var error: Error?
        game.getQuestions(gameId: gameId) { result in
            if case .failure(let err) = result {
                error = err
            }
            expectation.fulfill()
        }
        
        // Attente de l'invocation de l'expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Assertions de test
        XCTAssertNotNil(error)
        XCTAssertEqual((error as? MyError), .noUserConnected)
    }
    
    
    func testGetQuestions_cannotFetchGameData() {
        // Initialisation de l'environnement de test
        firebaseAuthService.userID = "TestUserId"
        let gameId = "TestId"
        let testError = NSError(domain: "Test", code: 1, userInfo: nil)
        firestoreService.stubbedDocumentError = testError
        
        // Création de l'expectation
        let expectation = XCTestExpectation(description: "Completion handler invoked")
        var error: Error?
        game.getQuestions(gameId: gameId) { result in
            if case .failure(let err) = result {
                error = err
            }
            expectation.fulfill()
        }
        
        // Attente de l'invocation de l'expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Assertions de test
        XCTAssertNotNil(error)
        XCTAssertEqual((error as NSError?)?.domain, testError.domain)
        XCTAssertEqual((error as NSError?)?.code, testError.code)
    }
    
    //-----------------------------------------------------------------------------------
    //                                 GET COMPLETED GAMES
    //-----------------------------------------------------------------------------------
    
    func testGetCompletedGames_success() {
        // Initialisation de l'environnement de test
        firebaseAuthService.userID = "TestUserId"
        firestoreService.stubbedQuerySnapshotData = fakeResponsesData.mockGamesData
        
        
        game.getCompletedGames() { result in
            if case .success(let games) = result {
                XCTAssertNotNil(games)
            }
        }
        
    }
    
    func testGetCompletedGames_noUserConnected() {
        // Initialisation de l'environnement de test
        firebaseAuthService.userID = nil
        
        
        game.getCompletedGames() { result in
            if case .failure(let error) = result {
                XCTAssertNotNil(error)
            }
        }
        
    }
    
    //-----------------------------------------------------------------------------------
    //                                 GET GAME DATA
    //-----------------------------------------------------------------------------------
    
    
    func testGetGameData_fail() {
        // Initialisation de l'environnement de test
        firebaseAuthService.userID = nil
        
        game.getGameData(gameId: "hygtfr") { result in
            if case .success(let gameData) = result {
                XCTAssertNotNil(gameData)
            }
        }
        
    }
    
    // MARK: - Tests for getCompletedGames
    func testGetCompletedGamesSuccess() {
        firestoreService.stubbedQuerySnapshotData = fakeResponsesData.mockGamesData
        firestoreService.stubbedDocumentError = nil
        firebaseAuthService.userID = "user_id_1"
        
        let expectation = self.expectation(description: "Get completed games")
        game.getCompletedGames() { result in
            switch result {
            case .success:
                XCTAssertEqual(FirebaseUser.shared.History!.count, fakeResponsesData.mockGamesData.count, "The number of completed games should match the mock data")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Get completed games failed with error: \(error)")
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetCompletedGamesFailure() {
        firestoreService.stubbedQuerySnapshotData = nil
        firestoreService.stubbedDocumentError = MyError.generalError
        firebaseAuthService.userID = "user_id_1"
        
        let expectation = self.expectation(description: "Get completed games failure")
        game.getCompletedGames() { result in
            switch result {
            case .success:
                XCTFail("Get completed games should have failed")
            case .failure:
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetCompletedGamesNoUserConnected() {
        firebaseAuthService.userID = nil
        
        let expectation = self.expectation(description: "Get completed games no user connected")
        game.getCompletedGames() { result in
            switch result {
            case .success:
                XCTFail("Get completed games should have failed due to no user connected")
            case .failure(let error):
                if case MyError.noUserConnected = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Unexpected error: \(error)")
                }
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    //-----------------------------------------------------------------------------------
    //                                 SAVE STATS
    //-----------------------------------------------------------------------------------
    
    func testSaveStats_success() {
        firebaseAuthService.userID = "TestUserId"
        let gameId = "TestId"
        let userAnswers = ["TestQuestionId": UserAnswer(selected_answer: "selected_answer", points: 0)]
        firestoreService.stubbedDocumentSnapshot = fakeResponsesData.mockAnswersData
        
        let expectation = XCTestExpectation(description: "Stats saved")
        
        game.saveStats(userAnswers: userAnswers, gameID: gameId) { result in
            if case .success = result {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testSaveStats_failure() {
        firebaseAuthService.userID = "TestUserId"
        let gameId = "TestId"
        let userAnswers = ["TestQuestionId": UserAnswer(selected_answer: "selected_answer", points: 0)]
        
        firestoreService.stubbedDocumentError = MyError.noUserConnected
        
        let expectation = XCTestExpectation(description: "Failed to save stats")
        
        game.saveStats(userAnswers: userAnswers, gameID: gameId) { result in
            if case .failure = result {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }
    
    //-----------------------------------------------------------------------------------
    //                                 LISTENER
    //-----------------------------------------------------------------------------------
    
    func testListenForGameStart_success() {
        firebaseAuthService.userID = "TestUserId"
        firestoreService.stubbedQuerySnapshotData = [["id": "TestGameId"]]

        let expectation = XCTestExpectation(description: "Game start listened for")

        game.listenForGameStart { result in
            if case .success = result {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testListenForGameStart_failure() {
        firebaseAuthService.userID = "TestUserId"
        firestoreService.stubbedDocumentError = MyError.noUserConnected

        let expectation = XCTestExpectation(description: "Failed to listen for game start")

        game.listenForGameStart { result in
            if case .failure = result {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }
    
    //-----------------------------------------------------------------------------------
    //                                 CONVERT DATA
    //-----------------------------------------------------------------------------------
    
    func testConvertTimestampsToDate() {
        let date = Date(timeIntervalSince1970: 1621840502) // 24 May 2021 07:55:02 GMT
        let timestamp = Timestamp(date: date)

        let data: [String: Any] = ["date": timestamp]

        let convertedData = game.convertTimestampsToDate(in: data)

        let convertedDate = convertedData["date"] as? String

        // Adjust the expected date string to the correct timezone
        XCTAssertEqual(convertedDate, "2021-05-24T09:15:02+0200")
    }
}

//
//  GameTests.swift
//  QuizTests
//
//  Created by Guillaume Bourlart on 18/05/2023.
//
@testable import Quiz
import XCTest

final class GameTests: XCTestCase {
    
    var sut: Game!
    var firestoreServiceStub: FirestoreServiceStub!
    var firebaseAuthServiceStub: FirebaseAuthServiceStub!
    
    override func setUp() {
        super.setUp()
        sut = Game(firestoreService: FirestoreServiceStub(), firebaseAuthService: FirebaseAuthServiceStub())
    }
    
    
    func testSearchCompetitiveLobby_GivenNoLobbies_ReturnsFailure() {
        // Given
        let expectedError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No lobbies found"])
        firestoreServiceStub.stubbedError = expectedError
        
        
        // When
        var resultError: Error?
        sut.searchCompetitiveLobby { result in
            switch result {
            case .failure(let error):
                resultError = error
            case .success:
                break
            }
        }
        
        // Then
        XCTAssertNotNil(resultError)
        XCTAssertEqual(resultError as NSError?, expectedError)
    }
    
    func testCreateCompetitiveLobby_GivenFirestoreError_ReturnsFailure() {
        // Given
        let expectedError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firestore error"])
        firestoreServiceStub.setDocumentStubbedError = expectedError

        // When
        var resultError: Error?
        sut.createCompetitiveLobby { result in
            switch result {
            case .failure(let error):
                resultError = error
            case .success:
                break
            }
        }

        // Then
        XCTAssertEqual(resultError as NSError?, expectedError)
    }

    func testCancelSearch_GivenFirestoreError_ReturnsFailure() {
        // Given
        let expectedError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firestore error"])
        firestoreServiceStub.deleteDocumentStubbedError = expectedError

        // When
        var resultError: Error?
        sut.cancelSearch { result in
            switch result {
            case .failure(let error):
                resultError = error
            case .success:
                break
            }
        }

        // Then
        XCTAssertEqual(resultError as NSError?, expectedError)
    }
    
    func testCreateCompetitiveLobby_GivenNoFirestoreError_ReturnsSuccess() {
        // Given
        firestoreServiceStub.setDocumentStubbedError = nil

        // When
        var isSuccess: Bool = false
        sut.createCompetitiveLobby { result in
            switch result {
            case .failure:
                break
            case .success:
                isSuccess = true
            }
        }

        // Then
        XCTAssertTrue(isSuccess)
    }

    func testCancelSearch_GivenNoFirestoreError_ReturnsSuccess() {
        // Given
        firestoreServiceStub.deleteDocumentStubbedError = nil

        // When
        var isSuccess: Bool = false
        sut.cancelSearch { result in
            switch result {
            case .failure:
                break
            case .success:
                isSuccess = true
            }
        }

        // Then
        XCTAssertTrue(isSuccess)
    }
    
    func testGetQuestions_GivenFirestoreError_ReturnsFailure() {
        // Given
        let expectedError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firestore error"])
        firestoreServiceStub.getDocumentStubbedError = expectedError
        firestoreServiceStub.stubbedDocumentSnapshot = fakeResponsesData.mockGameData

        // When
        var resultError: Error?
        sut.getQuestions(gameId: "dummy") { result in
            switch result {
            case .failure(let error):
                resultError = error
            case .success:
                break
            }
        }

        // Then
        XCTAssertEqual(resultError as NSError?, expectedError)
    }
    
    func testGetQuestions_GivenValidDocument_ReturnsSuccess() {
        // Given
        firestoreServiceStub.getDocumentStubbedError = nil
        let dummySnapshot = DocumentSnapshot(...) // Here you have to create a DocumentSnapshot instance representing a valid game.
        firestoreServiceStub.stubbedDocumentSnapshot = dummySnapshot

        // When
        var isSuccess: Bool = false
        sut.getQuestions(gameId: "dummy") { result in
            switch result {
            case .failure:
                break
            case .success:
                isSuccess = true
            }
        }

        // Then
        XCTAssertTrue(isSuccess)
    }
}

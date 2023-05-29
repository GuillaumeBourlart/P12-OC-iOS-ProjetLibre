//
//  Quizz_Culture_ge_ne_raleTests.swift
//  Quizz Culture généraleTests
//
//  Created by Guillaume Bourlart on 20/04/2023.
//

import XCTest


@testable import Quiz
import FirebaseAuth


final class OpenTriviaDatabaseManagerTests: XCTestCase {
    
    var service: Service!
    var sut: OpenTriviaDatabaseManager!
    var networkRequestStub: NetworkRequestStub!
    var currentUserStub: String!
    
    override func setUp() {
        super.setUp()
        networkRequestStub = NetworkRequestStub()
        service = Service(networkRequest: networkRequestStub)
        sut = OpenTriviaDatabaseManager(service: service)
        currentUserStub = "testUser"
    }
    
    override func tearDown() {
        sut = nil
        service = nil
        networkRequestStub = nil
        currentUserStub = nil
        super.tearDown()
    }
    
    func testFetchCategories_success() {
        // Given
        let jsonString = """
        {
            "trivia_categories": [
                {
                    "id": 9,
                    "name": "General Knowledge"
                },
                {
                    "id": 10,
                    "name": "Entertainment: Books"
                },
                {
                    "id": 11,
                    "name": "Entertainment: Film"
                }
            ]
        }
        """
        let jsonData = jsonString.data(using: .utf8)
        networkRequestStub.data = jsonData
        
        // When
        var fetchedCategories: [[String: Any]]?
        sut.fetchCategories { result in
            switch result {
            case .failure(_):XCTFail("Expected to succes")
            case .success(let categories):fetchedCategories = categories
            }
            
        }
        
        // Then
        XCTAssertNotNil(fetchedCategories)
    }
    
    func testFetchCategories_failure() {
        // Given
        networkRequestStub.error = NSError(domain: "", code: -1, userInfo: nil)
        
        // When
        var fetchedCategories: [[String: Any]]?
        sut.fetchCategories { result in
            switch result {
            case .failure(_):
                XCTFail("Expected to succes")
            case .success(let categories):
                fetchedCategories = categories
            }
            
            // Then
            XCTAssertNil(fetchedCategories)
        }
    }
        
        func testFetchQuestions_success() {
            // Given
            let jsonData = "{\"results\": [{\"category\": \"category1\", \"type\": \"multiple\", \"difficulty\": \"easy\", \"question\": \"What is the capital of France?\", \"correct_answer\": \"Paris\", \"incorrect_answers\": [\"London\", \"Berlin\", \"Madrid\"]}]}".data(using: .utf8)
            networkRequestStub.data = jsonData
            
            // When
            var fetchedQuestions: [UniversalQuestion]?
            var fetchedError: Error?
            sut.fetchQuestions(inCategory: 1, difficulty: nil) { result in
                switch result {
                case .success(let questions):
                    fetchedQuestions = questions
                case .failure(let error):
                    fetchedError = error
                }
            }
            
            // Then
            XCTAssertNil(fetchedError)
            XCTAssertNotNil(fetchedQuestions)
        }
        
        func testFetchQuestions_failure() {
            // Given
            networkRequestStub.error = NSError(domain: "", code: -1, userInfo: nil)
            
            // When
            var fetchedQuestions: [UniversalQuestion]?
            var fetchedError: Error?
            sut.fetchQuestions(inCategory: 1, difficulty: nil) { result in
                switch result {
                case .success(let questions):
                    fetchedQuestions = questions
                case .failure(let error):
                    fetchedError = error
                }
            }
            
            // Then
            XCTAssertNotNil(fetchedError)
            XCTAssertNil(fetchedQuestions)
        }
    }


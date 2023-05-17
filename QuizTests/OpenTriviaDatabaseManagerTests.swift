//
//  Quizz_Culture_ge_ne_raleTests.swift
//  Quizz Culture généraleTests
//
//  Created by Guillaume Bourlart on 20/04/2023.
//

import XCTest


@testable import QuizzCultureG


final class OpenTriviaDatabaseManagerTests: XCTestCase {
    
    var manager: OpenTriviaDatabaseManager!
    var service: Service!
    var networkRequestStub: NetworkRequestStub!
    
    override func setUp() {
        super.setUp()
        networkRequestStub = NetworkRequestStub()
        service = Service(networkRequest: networkRequestStub)
        manager = OpenTriviaDatabaseManager(service: service)
    }
    
    override func tearDown() {
        manager = nil
        service = nil
        networkRequestStub = nil
        super.tearDown()
    }
    
    func testFetchCategories() {
        // Given
        let expectedCategories: [NSDictionary] = [
            ["id": 1, "name": "Category 1"],
            ["id": 2, "name": "Category 2"]
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: ["trivia_categories": expectedCategories], options: [])
        networkRequestStub.data = jsonData
        
        // When
        let expectation = XCTestExpectation(description: "Fetch categories")
        manager.fetchCategories { (categories) in
            // Then
            XCTAssertEqual(categories as NSArray?, expectedCategories as NSArray?)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchCategoriesWithError() {
        // Given
        networkRequestStub.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error"])
        
        // When
        let expectation = XCTestExpectation(description: "Fetch categories with error")
        manager.fetchCategories { (categories) in
            // Then
            XCTAssertNil(categories)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchQuestions() {
        // Given
        let expectedQuestions: [[String: Any]] = [
            ["question": "Question 1", "correct_answer": "Answer 1"],
            ["question": "Question 2", "correct_answer": "Answer 2"]
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: expectedQuestions, options: [])
        networkRequestStub.data = jsonData
        
        // When
        let expectation = XCTestExpectation(description: "Fetch questions")
        manager.fetchQuestions(inCategory: nil, amount: 10, difficulty: nil) { (result) in
            // Then
            switch result {
            case .success(let questions):
                XCTAssertEqual(questions.count, expectedQuestions.count)
            case .failure(let error):
                XCTFail("Failed with error: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchQuestionsWithCategory() {
        // Given
        let expectedQuestions: [[String: Any]] = [
            ["question": "Question 1", "correct_answer": "Answer 1"],
            ["question": "Question 2", "correct_answer": "Answer 2"]
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: expectedQuestions, options: [])
        networkRequestStub.data = jsonData
        
        // When
        let expectation = XCTestExpectation(description: "Fetch questions with category")
        manager.fetchQuestions(inCategory: 1, amount: 10, difficulty: nil) { (result) in
            // Then
            switch result {
            case .success(let questions):
                XCTAssertEqual(questions.count, expectedQuestions.count)
            case .failure(let error):
                XCTFail("Failed with error: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    func testFetchQuestionsWithError() {
            // Given
            networkRequestStub.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error"])
            
            // When
            let expectation = XCTestExpectation(description: "Fetch questions with error")
            manager.fetchQuestions(inCategory: nil, amount: 10, difficulty: nil) { (result) in
                // Then
                switch result {
                case .success:
                    XCTFail("Fetch should have failed")
                case .failure(let error):
                    XCTAssertNotNil(error)
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }

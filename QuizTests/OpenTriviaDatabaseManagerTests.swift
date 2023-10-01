//
//  Quizz_Culture_ge_ne_raleTests.swift
//  Quizz Culture généraleTests
//
//  Created by Guillaume Bourlart on 20/04/2023.
//

import XCTest
@testable import Quiz


final class OpenTriviaDatabaseManagerTests: XCTestCase {
    
    var service: Service!
    var sut: OpenTriviaDatabaseManager!
    var networkRequestStub: NetworkRequestStub!
    var translatorNetworkRequestStub: NetworkRequestStub!
    
    override func setUp() {
        super.setUp()
        networkRequestStub = NetworkRequestStub()
        translatorNetworkRequestStub = NetworkRequestStub()
        let service = Service(networkRequest: networkRequestStub)
        let translatorService = Service(networkRequest: translatorNetworkRequestStub)
        sut = OpenTriviaDatabaseManager(service: service, translatorService: translatorService)
    }
    
    override func tearDown() {
        sut = nil
        service = nil
        networkRequestStub = nil
        super.tearDown()
    }
    
    func testGivenValideData_WhenFetchCategories_ThenReturnsSuccess() {
        // Given
        let jsonStringCategories = """
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
        guard let jsonDataCategories = jsonStringCategories.data(using: .utf8) else {return}
        
        // Add the translation responses to the translatorNetworkRequestStub.
        let jsonStringtranslateGeneralKnowledge = """
           {
               "translations": [
                   {
                       "detected_source_language": "EN",
                       "text": "Connaissance Générale"
                   }
               ]
           }
           """
        let jsonStringtranslateEntertainmentBooks = """
           {
               "translations": [
                   {
                       "detected_source_language": "EN",
                       "text": "Livres"
                   }
               ]
           }
           """
        let jsonStringtranslateEntertainmentFilm = """
           {
               "translations": [
                   {
                       "detected_source_language": "EN",
                       "text": "Film"
                   }
               ]
           }
           """
        guard let jsonDataTranslateGeneralKnowledge = jsonStringtranslateGeneralKnowledge.data(using: .utf8) else {return}
        guard let jsonDataTranslateEntertainmentBooks = jsonStringtranslateEntertainmentBooks.data(using: .utf8) else {return}
        guard let jsonDataTranslateEntertainmentFilm = jsonStringtranslateEntertainmentFilm.data(using: .utf8) else {return}
        
        translatorNetworkRequestStub.dataQueue = [jsonDataTranslateGeneralKnowledge, jsonDataTranslateEntertainmentBooks, jsonDataTranslateEntertainmentFilm]
        
        networkRequestStub.dataQueue = [jsonDataCategories]
        var fetchedError: Error?
        
        // When
        var fetchedCategories: [[String: Any]]?
        sut.fetchCategories { result in
            switch result {
            case .failure(let error):
                fetchedError = error
            case .success(let categories):
                fetchedCategories = categories
                print("categories : \(String(describing: fetchedCategories))")
                // Then
                XCTAssertNil(fetchedError)
                XCTAssertNotNil(fetchedCategories)
                // Add checks for translated categories
                XCTAssert(fetchedCategories!.contains(where: { $0["name"] as? String == "Connaissance Générale" }))
                XCTAssert(fetchedCategories!.contains(where: { $0["name"] as? String == "Livres" }))
                XCTAssert(fetchedCategories!.contains(where: { $0["name"] as? String == "Film" }))
            }
        }
    }
    
    func testGivenError_WhenFetchCategories_ThenReturnsFailure() {
        // Given
        networkRequestStub.error = NSError(domain: "", code: -1, userInfo: nil)
        var fetchedQuestions: [UniversalQuestion]?
        var fetchedError: Error?
        // When
        var fetchedCategories: [[String: Any]]?
        sut.fetchCategories { result in
            switch result {
            case .failure(let error):
                fetchedError = error
            case .success(let categories):
                fetchedCategories = categories
                // Then
                XCTAssertNil(fetchedCategories)
            }
            // Then
            XCTAssertNotNil(fetchedError)
            XCTAssertNil(fetchedQuestions)
            
            
        }
    }
    
    func testGivenValideData_WhenFetchQuestions_ThenReturnsSuccess() {
        // Given
        guard let jsonData = "{\"results\": [{\"category\": \"category1\", \"type\": \"multiple\", \"difficulty\": \"easy\", \"question\": \"What is the capital of France?\", \"correct_answer\": \"Paris\", \"incorrect_answers\": [\"London\", \"Berlin\", \"Madrid\"]}]}".data(using: .utf8) else {return}
        networkRequestStub.dataQueue = [jsonData]
        
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
            // Then
            XCTAssertNil(fetchedError)
            XCTAssertNotNil(fetchedQuestions)
        }
        
        
    }
    
    func testGivenError_WhenFetchQuestions_ThenReturnsFailure() {
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
            // Then
            XCTAssertNotNil(fetchedError)
            XCTAssertNil(fetchedQuestions)
        }
        
        
    }
    
}


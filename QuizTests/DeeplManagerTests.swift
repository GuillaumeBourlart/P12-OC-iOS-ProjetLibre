//
//  DeeplManagerTests.swift
//  QuizTests
//
//  Created by Guillaume Bourlart on 30/06/2023.
//
@testable import Quiz
import XCTest

final class DeeplManagerTests: XCTestCase {

    var sut: DeepLTranslator! // System Under Test
    var networkRequestStub: NetworkRequestStub!
        
        override func setUp() {
            super.setUp()
            networkRequestStub = NetworkRequestStub()
            sut = DeepLTranslator(service: Service(networkRequest: networkRequestStub))
        }

        override func tearDown() {
            sut = nil
            networkRequestStub = nil
            super.tearDown()
        }

        // ...

        func testTranslate_FailedToMakeURL() {
            // Arrange
            sut = DeepLTranslator(service: Service(networkRequest: networkRequestStub))
            sut.apiKey = "invalid key" // Cause the URL creation to fail

            // Act
            let translateExpectation = expectation(description: "Translate called")
            var translatedText: String?
            var receivedError: Error?
            sut.translate("Hello", targetLanguage: "FR") { result in
                switch result {
                case .success(let text):
                    translatedText = text
                case .failure(let error):
                    receivedError = error
                }
                translateExpectation.fulfill()
            }

            // Assert
            waitForExpectations(timeout: 1)
            XCTAssertNil(translatedText)
            XCTAssertNotNil(receivedError)
            // Modify to the actual error type
            // XCTAssertEqual(receivedError as? DeepLTranslator.DeepLError, DeepLTranslator.DeepLError.failedToMakeURL)
        }

        func testTranslate_ErrorDuringTranslation() {
            // Arrange
            let mockError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
            networkRequestStub.error = mockError

            // Act
            let translateExpectation = expectation(description: "Translate called")
            var translatedText: String?
            var receivedError: Error?
            sut.translate("Hello", targetLanguage: "FR") { result in
                switch result {
                case .success(let text):
                    translatedText = text
                case .failure(let error):
                    receivedError = error
                }
                translateExpectation.fulfill()
            }

            // Assert
            waitForExpectations(timeout: 1)
            XCTAssertNil(translatedText)
            XCTAssertNotNil(receivedError)
        }

        func testTranslate_NoDataInResponse() {
            // Arrange
            networkRequestStub.data = nil // No data is returned

            // Act
            let translateExpectation = expectation(description: "Translate called")
            var translatedText: String?
            var receivedError: Error?
            sut.translate("Hello", targetLanguage: "FR") { result in
                switch result {
                case .success(let text):
                    translatedText = text
                case .failure(let error):
                    receivedError = error
                }
                translateExpectation.fulfill()
            }

            // Assert
            waitForExpectations(timeout: 1)
            XCTAssertNil(translatedText)
            XCTAssertNotNil(receivedError)
            XCTAssertEqual(receivedError as? DeepLTranslator.DeepLError, DeepLTranslator.DeepLError.noDataInResponse)
        }

}

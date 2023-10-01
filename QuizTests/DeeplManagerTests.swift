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
        networkRequestStub.dataQueue = nil
        networkRequestStub.error = nil
        networkRequestStub = nil
        super.tearDown()
    }
    
    // Test de la traduction réussie
    func testGivenValideData_WhenTranslateText_ThenReturnsSuccess() {
        guard let jsonData = "{\"translations\": [{\"detected_source_language\": \"EN\", \"text\": \"Bonjour\"}]}".data(using: .utf8) else {return}
        networkRequestStub.dataQueue = [jsonData]
        
        let expectation = self.expectation(description: "La traduction du texte réussit")
        sut.translate("Hello", targetLanguage: "FR") { result in
            switch result {
            case .success(let translation):
                XCTAssertEqual(translation, "Bonjour")
            case .failure(let error):
                XCTFail("Attendu le succès, obtenu \(error) à la place")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    // Test de l'échec de la traduction
    func testGivenError_WhenTranslateText_ThenReturnsFailure() {
        networkRequestStub.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Erreur réseau"])
        
        let expectation = self.expectation(description: "La traduction du texte échoue")
        sut.translate("Hello", targetLanguage: "FR") { result in
            switch result {
            case .success(let translation):
                XCTFail("Attendu l'échec, obtenu \(translation) à la place")
            case .failure(_):
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }
    
    
    
    // Test de la traduction réussie des questions
    func testGivenValideData_WhenTranslateQuestion_ThenReturnsSuccess() {
        guard let jsonData = "{\"translations\": [{\"detected_source_language\": \"EN\", \"text\": \"Bonjour\"}]}".data(using: .utf8) else {return}
        networkRequestStub.dataQueue = [jsonData, jsonData, jsonData, jsonData, jsonData, jsonData] // Données pour chaque traduction
        
        let expectation = self.expectation(description: "La traduction des questions réussit")
        let questions = [
            UniversalQuestion(id: "1", category: "", type: "", difficulty: "", question: "Hello", correct_answer: "Yes", incorrect_answers: ["No", "No", "No"], explanation: "Because it's right"),
        ]
        sut.translateQuestions(questions: questions, to: "FR") { translatedQuestions in
            XCTAssertEqual(translatedQuestions.first?.question, "Bonjour")
            XCTAssertEqual(translatedQuestions.first?.correct_answer, "Bonjour")
            XCTAssertEqual(translatedQuestions.first?.incorrect_answers.first, "Bonjour")
            XCTAssertEqual(translatedQuestions.first?.explanation, "Bonjour")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    // Test de l'échec de la traduction des questions
    func testGivenError_WhenTranslateQuestion_ThenReturnsFailure() {
        networkRequestStub.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Erreur réseau"])
        
        let expectation = self.expectation(description: "La traduction des questions échoue")
        let questions = [
            UniversalQuestion(id: "1", category: "", type: "", difficulty: "", question: "Hello", correct_answer: "Yes", incorrect_answers: ["No", "No", "No"], explanation: "Because it's right"),
        ]
        sut.translateQuestions(questions: questions, to: "FR") { translatedQuestions in
            XCTAssertEqual(translatedQuestions.first?.question, "Hello") // Le texte original devrait rester si la traduction échoue
            XCTAssertEqual(translatedQuestions.first?.correct_answer, "Yes") // Le texte original devrait rester si la traduction échoue
            XCTAssertEqual(translatedQuestions.first?.incorrect_answers.first, "No") // Le texte original devrait rester si la traduction échoue
            XCTAssertEqual(translatedQuestions.first?.explanation, "Because it's right") // Le texte original devrait rester si la traduction échoue
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    // Test de la traduction réussie pour les questions
    func testGivenValideData_WhenTranslateQuestionWithString_ThenReturnsSuccess() {
        // Préparation des données de test
        let question1 = UniversalQuestion(id: "1", category: "category", type: "type", difficulty: "easy", question: "Hello", correct_answer: "World", incorrect_answers: ["Incorrect", "Incorrect", "Incorrect"], explanation: "Explanation")
        let questionDict = ["1": question1]
        
        guard let jsonData = "{\"translations\": [{\"detected_source_language\": \"EN\", \"text\": \"Bonjour\"}]}".data(using: .utf8) else {return}
        networkRequestStub.dataQueue = [jsonData, jsonData, jsonData, jsonData, jsonData, jsonData] // On suppose que toutes les traductions réussissent
        
        // Création d'une attente
        let expectation = self.expectation(description: "La traduction des questions réussit")
        
        sut.translateQuestionsWithString(questions: questionDict, to: "FR") { result in
            // Vérifier que chaque partie de la question a été traduite
            for (_, question) in result {
                XCTAssertEqual(question.question, "Bonjour") // Remplacez par votre valeur attendue
                XCTAssertEqual(question.correct_answer, "Bonjour") // Remplacez par votre valeur attendue
                XCTAssertEqual(question.incorrect_answers.first, "Bonjour") // Remplacez par votre valeur attendue
                XCTAssertEqual(question.explanation, "Bonjour") // Remplacez par votre valeur attendue
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    // Test de l'échec de la traduction pour les questions
    func testGivenError_WhenTranslateQuestionWithString_ThenReturnsFailure() {
        // Préparation des données de test
        let question1 = UniversalQuestion(id: "1", category: "category", type: "type", difficulty: "easy", question: "Hello", correct_answer: "World", incorrect_answers: ["Incorrect", "Incorrect", "Incorrect"], explanation: "Explanation")
        let questionDict = ["1": question1]
        
        networkRequestStub.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Erreur réseau"])
        
        // Création d'une attente
        let expectation = self.expectation(description: "La traduction des questions échoue")
        
        sut.translateQuestionsWithString(questions: questionDict, to: "FR") { result in
            // Vérifier que chaque partie de la question n'a pas été traduite
            for (_, question) in result {
                XCTAssertEqual(question.question, "Hello") // On s'attend à ce que la valeur reste inchangée en cas d'échec de la traduction
                XCTAssertEqual(question.correct_answer, "World") // On s'attend à ce que la valeur reste inchangée en cas d'échec de la traduction
                XCTAssertEqual(question.incorrect_answers.first, "Incorrect") // On s'attend à ce que la valeur reste inchangée en cas d'échec de la traduction
                XCTAssertEqual(question.explanation, "Explanation") // On s'attend à ce que la valeur reste inchangée en cas d'échec de la traduction
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}

//
//  DeeplTranslatorManager.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 16/06/2023.
//

import Foundation

enum DeepLError: Error {
    case invalidURL
    case noTranslationAvailable
    case noDataInResponse
    case failedToMakeURL
}

// Class to get translation from Deepl(API)
class DeepLTranslator {
    // Properties
    var apiKey = "d35a5eeb-9d0c-4229-65e6-50a5ac70d7be:fx" // API key
    var service: Service // Used service of AlamofireNetwork (stub or not)
    init(service: Service) {
        self.service = service
    }
    
    // Function to translate a text
    func translate(_ text: String, targetLanguage: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let url = "https://api-free.deepl.com/v2/translate"
        var urlComponent = URLComponents(string: url)
        //  We add arguments to the urlComponent
        urlComponent?.queryItems = [
            URLQueryItem(name: "source_lang", value: "EN"),
            URLQueryItem(name: "target_lang", value: targetLanguage),
            URLQueryItem(name: "text", value: text ),
            URLQueryItem(name: "auth_key", value: apiKey)
        ]
        guard let url = urlComponent?.url else {
            completion(.failure(DeepLError.failedToMakeURL))
            return
        }
        
        service.load(url: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let deepLResponse = try decoder.decode(DeepLResponse.self, from: data)
                    if let translation = deepLResponse.translations.first {
                        completion(.success(translation.text))
                    } else {
                        completion(.failure(DeepLError.noTranslationAvailable))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(DeepLError.noDataInResponse))
            }
        }
    }
    
    // Function to translate a single UniversalQuestion. this function use translate()
    private func translateSingleQuestion(_ question: UniversalQuestion, to: String, completion: @escaping (UniversalQuestion) -> Void) {
        let dispatchGroup = DispatchGroup()
        
        var translatedQuestion: String?
        var translatedCorrectAnswer: String?
        var translatedIncorrectAnswers: [String]?
        var translatedExplanation: String?
        
        dispatchGroup.enter()
        translate(question.question, targetLanguage: to) { result in
            switch result {
            case .success(let translation):
                translatedQuestion = translation
            case .failure(let error):
                print("Error translating question: \(error)")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        translate(question.correct_answer, targetLanguage: to) { result in
            switch result {
            case .success(let translation):
                translatedCorrectAnswer = translation
            case .failure(let error):
                print("Error translating correct answer: \(error)")
            }
            dispatchGroup.leave()
        }
        
        for incorrectAnswer in question.incorrect_answers {
            dispatchGroup.enter()
            translate(incorrectAnswer, targetLanguage: to) { result in
                switch result {
                case .success(let translation):
                    if translatedIncorrectAnswers == nil {
                        translatedIncorrectAnswers = [translation]
                    } else {
                        translatedIncorrectAnswers?.append(translation)
                    }
                case .failure(let error):
                    print("Error translating incorrect answer: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        
        if let explanation = question.explanation {
            dispatchGroup.enter()
            translate(explanation, targetLanguage: to) { result in
                switch result {
                case .success(let translation):
                    translatedExplanation = translation
                case .failure(let error):
                    print("Error translating explanation: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let translatedQuestionInstance = UniversalQuestion(
                id: question.id,
                category: question.category,
                type: question.type,
                difficulty: question.difficulty,
                question: translatedQuestion ?? question.question,
                correct_answer: translatedCorrectAnswer ?? question.correct_answer,
                incorrect_answers: translatedIncorrectAnswers ?? question.incorrect_answers,
                explanation: translatedExplanation ?? question.explanation
            )
            completion(translatedQuestionInstance)
        }
    }
    
    // Function to translate questions. Used to translate questions in the game controller
    func translateQuestions(questions: [UniversalQuestion], to: String, completion: @escaping ([UniversalQuestion]) -> Void) {
        var newArray = [UniversalQuestion]()
        let dispatchGroup = DispatchGroup()
        
        for question in questions {
            dispatchGroup.enter()
            translateSingleQuestion(question, to: to) { translatedQuestion in
                newArray.append(translatedQuestion)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(newArray)
        }
    }
    
    // Function to translate questions. Used to translate questions of GameData in result controller
    func translateQuestionsWithString(questions: [String: UniversalQuestion], to: String, completion: @escaping ([String: UniversalQuestion]) -> Void) {
        var translatedDict = [String: UniversalQuestion]()
        let dispatchGroup = DispatchGroup()
        
        for (key, question) in questions {
            dispatchGroup.enter()
            translateSingleQuestion(question, to: to) { translatedQuestion in
                translatedDict[key] = translatedQuestion
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(translatedDict)
        }
    }
    
    
}




//
//  DeeplTranslatorManager.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 16/06/2023.
//

import Foundation

class DeepLTranslator {
    let apiKey = "d35a5eeb-9d0c-4229-65e6-50a5ac70d7be:fx"
    var service: Service

    init(service: Service) {
        self.service = service
    }

    func translate(_ text: String, targetLanguage: String, completion: @escaping (Result<String, Error>) -> Void) {
        
print("target : \(targetLanguage)")
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
            completion(.failure(MyError.failedToMakeURL)) // a modifier
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
}

struct DeepLResponse: Codable {
    let translations: [Translation]
}

struct Translation: Codable {
    let text: String
}

enum DeepLError: Error {
    case invalidURL
    case noTranslationAvailable
    case noDataInResponse
}


func translateQuestions(questions : [UniversalQuestion], to: String, completion: @escaping ([UniversalQuestion]) -> Void) {
    var newArray = [UniversalQuestion]()
    let translator = DeepLTranslator(service: Service(networkRequest: AlamofireNetworkRequest()))
    let dispatchGroup = DispatchGroup()

    for question in questions {
        var translatedQuestion: String?
        var translatedCorrectAnswer: String?
        var translatedIncorrectAnswers: [String]?
        var translatedExplanation: String?

        dispatchGroup.enter()
        translator.translate(question.question, targetLanguage: to) { result in
            switch result {
            case .success(let translation):
                translatedQuestion = translation
            case .failure(let error):
                print("Error translating question: \(error)")
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        translator.translate(question.correct_answer, targetLanguage: to) { result in
            switch result {
            case .success(let translation):
                translatedCorrectAnswer = translation
            case .failure(let error):
                print("Error translating correct answer: \(error)")
            }
            dispatchGroup.leave()
        }

        // Translate each incorrect answer
        question.incorrect_answers.forEach { incorrectAnswer in
            dispatchGroup.enter()
            translator.translate(incorrectAnswer, targetLanguage: to) { result in
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
            translator.translate(explanation, targetLanguage: to) { result in
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
            let translatedQuestion = UniversalQuestion(
                id: question.id,
                category: question.category,
                type: question.type,
                difficulty: question.difficulty,
                question: translatedQuestion ?? question.question,
                correct_answer: translatedCorrectAnswer ?? question.correct_answer,
                incorrect_answers: translatedIncorrectAnswers ?? question.incorrect_answers,
                explanation: translatedExplanation ?? question.explanation
            )
            // Append the translated question to the newArray
            newArray.append(translatedQuestion)
            // Check if all translations are completed
            if newArray.count == questions.count {
                completion(newArray)
            }
        }
    }
}

func translateQuestions(questions : [String: UniversalQuestion], to: String, completion: @escaping ([String: UniversalQuestion]) -> Void) {
    var translatedDict = [String: UniversalQuestion]()
    let translator = DeepLTranslator(service: Service(networkRequest: AlamofireNetworkRequest()))
    let dispatchGroup = DispatchGroup()
    let questionPairs = Array(questions)
    
    for pair in questionPairs {
        let questionID = pair.key
        var question = pair.value
        var translatedQuestion: String?
        var translatedCorrectAnswer: String?
        var translatedIncorrectAnswers: [String]?
        var translatedExplanation: String?

        dispatchGroup.enter()
        translator.translate(question.question, targetLanguage: to) { result in
            switch result {
            case .success(let translation):
                translatedQuestion = translation
            case .failure(let error):
                print("Error translating question: \(error)")
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        translator.translate(question.correct_answer, targetLanguage: to) { result in
            switch result {
            case .success(let translation):
                translatedCorrectAnswer = translation
            case .failure(let error):
                print("Error translating correct answer: \(error)")
            }
            dispatchGroup.leave()
        }

        // Translate each incorrect answer
        question.incorrect_answers.forEach { incorrectAnswer in
            dispatchGroup.enter()
            translator.translate(incorrectAnswer, targetLanguage: to) { result in
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
            translator.translate(explanation, targetLanguage: to) { result in
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
            let translatedQuestion = UniversalQuestion(
                id: question.id,
                category: question.category,
                type: question.type,
                difficulty: question.difficulty,
                question: translatedQuestion ?? question.question,
                correct_answer: translatedCorrectAnswer ?? question.correct_answer,
                incorrect_answers: translatedIncorrectAnswers ?? question.incorrect_answers,
                explanation: translatedExplanation ?? question.explanation
            )
            translatedDict[questionID] = translatedQuestion
            if translatedDict.count == questions.count {
                completion(translatedDict)
            }
        }
    }
}



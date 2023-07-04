//
//  APIManager.swift
//  Quizz Culture générale
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import Foundation
import Alamofire
import FirebaseAuth

class OpenTriviaDatabaseManager {
    
    var service = Service(networkRequest: AlamofireNetworkRequest()) // service that allows to stub alamofire
    let translator = DeepLTranslator(service: Service(networkRequest: AlamofireNetworkRequest()))
    // The initializer for the RecipeService class
    init(service: Service) {
        self.service = service
    }
    private var currentUserId: String? { return Auth.auth().currentUser?.uid } // get current UID
    static var categories: [[String: Any]]?
    
    // Function to display TriviaDB categories
    func fetchCategories(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        guard self.currentUserId != nil else { completion(.failure(FirebaseError.noUserConnected)) ; return}
        let urlString = "https://opentdb.com/api_category.php"

        guard let url = URL(string: urlString) else {
            completion(.failure(FirebaseError.failedToMakeURL))
            return
        }

        service.load(url: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let json = jsonObject as? [String: Any],
                          let categoriesJSON = json["trivia_categories"] as? [[String: Any]] else {
                        completion(.failure(FirebaseError.invalidJsonFormat))
                        return
                    }
                    
                    // Begin the translation process
                    var translatedCategories = categoriesJSON
                    var translatedCategoriesCount = 0
                    for index in 0..<translatedCategories.count {
                        self.translator.translate(translatedCategories[index]["name"] as! String, targetLanguage: "FR") { result in
                            switch result {
                            case .failure(let error):
                                print("Failed to translate category: \(error)")
                            case .success(let translatedName):
                                var nameWithoutColon = translatedName
                                if let range = translatedName.range(of: ":") {
                                    nameWithoutColon = String(translatedName[range.upperBound...])
                                }
                                translatedCategories[index]["name"] = nameWithoutColon.trimmingCharacters(in: .whitespaces)
                            }
                            translatedCategoriesCount += 1
                            if translatedCategoriesCount == translatedCategories.count {
                                OpenTriviaDatabaseManager.categories = translatedCategories
                                completion(.success(translatedCategories))
                            }
                        }
                    }

                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(error ?? FirebaseError.noDataInResponse))
            }
        }
    }
    
    // Function to get questions from TrviaDB
    func fetchQuestions(inCategory categoryId: Int?, amount: Int = 10, difficulty: String?, completion: @escaping (Result<[UniversalQuestion], Error>) -> Void) {
        guard self.currentUserId != nil else { completion(.failure(FirebaseError.noUserConnected)) ; return }
        
        var urlString = "https://opentdb.com/api.php?amount=\(amount)&type=multiple"
        if let categoryId = categoryId { urlString += "&category=\(categoryId)"}
        if let difficulty = difficulty { urlString += "&difficulty=\(difficulty)"}
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        service.load(url: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    guard var json = jsonObject as? [String: Any],
                          var questionsData = json["results"] as? [[String: Any]] else {
                        completion(.failure(FirebaseError.invalidJsonFormat))
                        return
                    }

                    for (index, _) in questionsData.enumerated() {
                        if var question = questionsData[index]["question"] as? String {
                            question = question.stringByDecodingHTMLEntities ?? question
                            questionsData[index]["question"] = question
                        }
                        if var correctAnswer = questionsData[index]["correct_answer"] as? String {
                            correctAnswer = correctAnswer.stringByDecodingHTMLEntities ?? correctAnswer
                            questionsData[index]["correct_answer"] = correctAnswer
                        }
                        if var incorrectAnswers = questionsData[index]["incorrect_answers"] as? [String] {
                            for (i, _) in incorrectAnswers.enumerated() {
                                incorrectAnswers[i] = incorrectAnswers[i].stringByDecodingHTMLEntities ?? incorrectAnswers[i]
                            }
                            questionsData[index]["incorrect_answers"] = incorrectAnswers
                        }
                    }

                    json["results"] = questionsData
                    let jsonData = try JSONSerialization.data(withJSONObject: questionsData, options: [])
                    let decoder = JSONDecoder()
                    let questions = try decoder.decode([UniversalQuestion].self, from: jsonData)
                    completion(.success(questions))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(error ?? FirebaseError.noDataInResponse))
            }
        }
    }
    
}

// Extension to decode HTML entities
extension String {
    var stringByDecodingHTMLEntities: String? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return nil
        }

        return attributedString.string
    }
}

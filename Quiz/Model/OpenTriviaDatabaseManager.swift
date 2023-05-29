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
    
    var service = Service(networkRequest: AlamofireNetworkRequest())
    // The initializer for the RecipeService class
    init(service: Service) {
        self.service = service
    }
    
    private var currentUserId: String? { return Auth.auth().currentUser?.uid }
    
    func fetchCategories(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        guard self.currentUserId != nil else { completion(.failure(MyError.noUserConnected)) ; return}
        let urlString = "https://opentdb.com/api_category.php"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(MyError.failedToMakeURL))
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
                        completion(.failure(MyError.invalidJsonFormat))
                        return
                    }
                    completion(.success(categoriesJSON))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(error ?? MyError.noDataInResponse))
            }
        }
    }
    
    func fetchQuestions(inCategory categoryId: Int?, amount: Int = 10, difficulty: String?, completion: @escaping (Result<[UniversalQuestion], Error>) -> Void) {
        guard self.currentUserId != nil else { completion(.failure(MyError.noUserConnected)) ; return }
        
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
                    guard let json = jsonObject as? [String: Any],
                          let questionsData = json["results"] as? [[String: Any]] else {
                        completion(.failure(MyError.invalidJsonFormat))
                        return
                    }
                    let jsonData = try JSONSerialization.data(withJSONObject: questionsData, options: [])
                    let decoder = JSONDecoder()
                    let questions = try decoder.decode([UniversalQuestion].self, from: jsonData)
                    completion(.success(questions))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(error ?? MyError.noDataInResponse))
            }
        }
    }
    
}

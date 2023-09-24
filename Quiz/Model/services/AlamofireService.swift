//
//  File.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

//
//  AlamofireService.swift
//  Reciplease
//
//  Created by Guillaume Bourlart on 07/03/2023.
//

import Foundation
import Alamofire

// Defines a protocol for performing network requests.
protocol NetworkRequest {
    // Method that performs a network request and calls completion with the result.
    func request(_ request: URLRequest, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void)
}

// Implements the NetworkRequest protocol using Alamofire for networking.
class AlamofireNetworkRequest: NetworkRequest {
    // Executes the network request using Alamofire.
    func request(_ request: URLRequest, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        // Sends a request with Alamofire.
        AF.request(request)
            .validate(statusCode: 200..<300)  // Validates that status code is between 200 and 299.
            .responseData { response in       // Handle the response data.
                switch response.result {
                case .success(let data):      // On success, forward the data.
                    completion(data, response.response, nil)
                case .failure(let error):     // On failure, forward the error.
                    completion(nil, response.response, error)
                }
            }
    }
}

// Represents a general service for loading data from a URL.
class Service {
    // Holds a reference to the network request object.
    var networkRequest: NetworkRequest
    
    // Initializes the Service with a network request provider.
    init(networkRequest: NetworkRequest) {
        self.networkRequest = networkRequest
    }
    
    // Loads data from a given URL.
    func load(url: URL, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        let request = URLRequest(url: url) // Creates a URLRequest from the given URL.
        // Delegates the network request to the network request object.
        networkRequest.request(request, completion: completion)
    }
}

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


protocol NetworkRequest {
    func request(_ request: URLRequest, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void)
}

class AlamofireNetworkRequest: NetworkRequest {
    func request(_ request: URLRequest, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        AF.request(request).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success(let data):
                completion(data, response.response, nil)
            case .failure(let error):
                completion(nil, response.response, error)
            }
        }
    }
}

class Service {
    var networkRequest: NetworkRequest

    init(networkRequest: NetworkRequest) {
        self.networkRequest = networkRequest
    }
    
    func load(url: URL, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        let request = URLRequest(url: url)
        networkRequest.request(request, completion: completion)
    }
}

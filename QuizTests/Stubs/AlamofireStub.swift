//
//  Stub.swift
//  Quizz CultureGTests
//
//  Created by Guillaume Bourlart on 13/05/2023.
//
@testable import Quiz
import XCTest


class NetworkRequestStub: NetworkRequest {
    var dataQueue: [Data]?
    var error: Error?
    
    func request(_ request: URLRequest, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        if let data = dataQueue?.first {
            dataQueue?.removeFirst()
            completion(data, nil, nil)
            
        }else{
            completion(nil, nil, error)
            
        }
    }
}

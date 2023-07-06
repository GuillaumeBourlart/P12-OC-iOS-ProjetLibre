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
        print("appelé")
        if let data = dataQueue?.first {
            dataQueue?.removeFirst()
            print("fait1")
            completion(data, nil, nil)
            
        }else{
            print("fait2")
            completion(nil, nil, error)
            
        }
    }
}

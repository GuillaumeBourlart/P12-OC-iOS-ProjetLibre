//
//  Stub.swift
//  Quizz CultureGTests
//
//  Created by Guillaume Bourlart on 13/05/2023.
//
@testable import Quiz
import Foundation
class NetworkRequestStub: NetworkRequest {
    var data: Data?
    var error: Error?

    func request(_ request: URLRequest, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        completion(data, nil, error)
    }
}

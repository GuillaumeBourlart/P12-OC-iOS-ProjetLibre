//
//  FirebaseStub.swift
//  QuizTests
//
//  Created by Guillaume Bourlart on 18/05/2023.
//

@testable import Quiz
import FirebaseAuth
import FirebaseFirestore

class FirestoreServiceStub: FirestoreServiceProtocol {
    
    var stubbedQuerySnapshotData: [[String: Any]]?
    var stubbedDocumentSnapshot: [String: Any]?
    var stubbedDocumentError: Error?
    
    
    func getDocuments(in collection: String, whereFields fields: [FirestoreCondition], completion: @escaping ([[String : Any]]?, Error?) -> Void) {
        completion(stubbedQuerySnapshotData, stubbedDocumentError)
    }
    
    func getDocument(in collection: String, documentId: String, completion: @escaping ([String : Any]?, Error?) -> Void) {
        completion(stubbedDocumentSnapshot, stubbedDocumentError)
    }

    
    func setData(in collection: String, documentId: String, data: [String : Any], completion: @escaping (Error?) -> Void) {
        completion(stubbedDocumentError)
    }
    
    func updateDocument(in collection: String, documentId: String, data: [String : Any], completion: @escaping (Error?) -> Void) {
        completion(stubbedDocumentError)
    }
    
    
    func deleteDocument(in collection: String, documentId: String, completion: @escaping (Error?) -> Void) {
        completion(stubbedDocumentError)
    }
}

class FirebaseAuthServiceStub: FirebaseAuthServiceProtocol {
    
    var stubbedQuerySnapshotData: [[String: Any]]?
    var stubbedDocumentSnapshot: [String: Any]?
    var stubbedDocumentError: Error?
    
    var currentUserID: String? {
        // Retourne un ID utilisateur factice
        return userID
    }
    var userID: String?
    
    func signInUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        if stubbedDocumentError != nil {
            print(1)
            completion(.failure(stubbedDocumentError!))
        }else{
            completion(.success(()))
        }
    }
    
    func createUser(withEmail email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        if stubbedDocumentError != nil {
            completion(.failure(stubbedDocumentError!))
        }else{
            completion(.success(currentUserID!))
        }
    }
}

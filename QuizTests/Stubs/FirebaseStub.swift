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
    
    
    var stubbedError: Error?
    var setDocumentStubbedError: Error?
    var deleteDocumentStubbedError: Error?
    var stubbedQuerySnapshot: QuerySnapshot?
    var stubbedDocumentSnapshot: DocumentSnapshot?
    var stubbedDocumentError: Error?
    
    func getDocuments(in collection: String, whereFields fields: [(String, Any)], completion: @escaping (QuerySnapshot?, Error?) -> Void) {
        completion(stubbedQuerySnapshot, stubbedError)
    }
    
    func getDocument(in collection: String, documentId: String, completion: @escaping (DocumentSnapshot?, Error?) -> Void) {
            completion(stubbedDocumentSnapshot, stubbedDocumentError)
        }
    
    func setDocument(in collection: String, documentId: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        completion(setDocumentStubbedError)
    }
    
    func deleteDocument(in collection: String, documentId: String, completion: @escaping (Error?) -> Void) {
        completion(deleteDocumentStubbedError)
    }
}

class FirebaseAuthServiceStub: FirebaseAuthServiceProtocol {
    
    
    var currentUserID: String? {
        // Retourne un ID utilisateur factice
        return "12345"
    }
    
    func signInUser(email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        
    }
    
    func createUser(withEmail email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        
    }
}

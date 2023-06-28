//
//  FirebaseStub.swift
//  QuizTests
//
//  Created by Guillaume Bourlart on 18/05/2023.
//
import XCTest
@testable import Quiz
import Firebase

class FirebaseServiceStub: FirebaseServiceProtocol {
   
    var stubbedQuerySnapshotData: [[String: Any]]?
    var stubbedDocumentSnapshot: [String: Any]?
    var stubbedDocumentError: Error?
    
    
    var userID: String? = "userId"
    var currentUserID: String? {
        get {
            // Retourne un ID utilisateur factice
            return userID
        }
        set {
            userID = newValue
        }
    }
    
    func getDocuments(in collection: String, whereFields fields: [FirestoreCondition], completion: @escaping ([[String : Any]]?, Error?) -> Void) {
        completion(stubbedQuerySnapshotData, stubbedDocumentError)
    }
    
    func getDocument(in collection: String, documentId: String, completion: @escaping ([String : Any]?, Error?) -> Void) {
        completion(stubbedDocumentSnapshot, stubbedDocumentError)
    }
    
    func setDataWithMerge(in collection: String, documentId: String, data: [String : Any], merge: Bool, completion: @escaping (Error?) -> Void) {
        
    }
    
    func addDocumentSnapshotListener(in collection: String, documentId: String, completion: @escaping (Result<[String : Any], Error>) -> Void) -> ListenerRegistration {
        
       
    }
    
    func addCollectionSnapshotListener(in collection: String, completion: @escaping (Result<[[String : Any]], Error>) -> Void) -> ListenerRegistration {
        
    }
    
    func createGameAndDeleteLobby(gameData: [String : Any], gameId: String, lobbyId: String, completion: @escaping (Error?) -> Void) {
        
    }
    
    func signOutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        
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


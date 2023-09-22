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
    
    
   
    
    func isUserSignedIn() -> Bool {
        return currentUserID != nil
    }
    
    func resetPassword(for email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        if let error = stubbedDocumentError {
            completion(.failure(error))
            
        }else{
            completion(.success(()))
        }
    }
    
    var stubbedDocumentError: Error?
    var stubbedListenerData: [String: Any]?
    
    var stubbedQuerySnapshotDatas: [[[String: Any]]]?
    var stubbedDocumentSnapshots: [[String: Any]]?
    
    var stubbedDownloadData: Data?
    var stubbedStorageURL: String = "storageUrl"
    var userID: String? = "userId"
    var currentUserID: String? {
        get {return userID}
        set {userID = newValue}
    }
    
    func getDocuments(in collection: String, whereFields fields: [FirestoreCondition], completion: @escaping (Result<[[String : Any]], Error>) -> Void) {
        guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return}
        if let error = stubbedDocumentError {
            completion(.failure(error))
        } else if let data = stubbedQuerySnapshotDatas?.first {
            stubbedQuerySnapshotDatas?.removeFirst()
            completion(.success(data))
        }else {
            completion(.success([]))
        }
    }
    
    func getDocument(in collection: String, documentId: String, completion: @escaping (Result<[String : Any], Error>) -> Void) {
        guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return}
        if let error = stubbedDocumentError {
            completion(.failure(error))
        } else if let data = stubbedDocumentSnapshots?.first {
            stubbedDocumentSnapshots?.removeFirst()
            completion(.success(data))
        }else {
            completion(.success([:]))
        }
    }
    
    func setDataWithMerge(in collection: String, documentId: String, data: [String : Any], merge: Bool, completion: @escaping (Error?) -> Void) {
        guard isUserSignedIn() else {completion(FirebaseServiceError.noUserConnected); return}
        completion(stubbedDocumentError)
    }
    
    
    
    func addDocumentSnapshotListener(in collection: String, documentId: String, completion: @escaping (Result<[String : Any], Error>) -> Void) -> ListenerRegistration? {
        guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return nil}
        if let error = stubbedDocumentError {
            completion(.failure(error))
        } else if let data = stubbedListenerData {
            completion(.success(data))
        }
        return ListenerRegistrationStub()
    }
    
    
    func signOutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return}
        if stubbedDocumentError != nil {
            completion(.failure(stubbedDocumentError!))
        }else{
            completion(.success(()))
        }
    }
    
    
    func setData(in collection: String, documentId: String, data: [String : Any], completion: @escaping (Error?) -> Void) {
        guard isUserSignedIn() else {completion(FirebaseServiceError.noUserConnected); return}
        
        completion(stubbedDocumentError)
    }
    
    func updateDocument(in collection: String, documentId: String, data: [String : Any], completion: @escaping (Error?) -> Void) {
        guard isUserSignedIn() else {completion(FirebaseServiceError.noUserConnected); return}
        
        completion(stubbedDocumentError)
    }
    
    
    func deleteDocument(in collection: String, documentId: String, completion: @escaping (Error?) -> Void) {
        guard isUserSignedIn() else {completion(FirebaseServiceError.noUserConnected); return}
        
        completion(stubbedDocumentError)
    }
    
    func storeData(in folder: String, fileName: String, data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return}
        
            if let error = stubbedDocumentError {
                completion(.failure(error))
            } else {
                completion(.success(stubbedStorageURL))
            }
        }

        func downloadData(from url: String, completion: @escaping (Result<Data, Error>) -> Void) {
            guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return}
            
            if let error = stubbedDocumentError {
                completion(.failure(error))
            } else if let data = stubbedDownloadData {
                completion(.success(data))
            } else {
                completion(.success(Data()))
            }
        }
    
    func deleteData(in folder: String, fileName: String, completion: @escaping (Error?) -> Void) {
        guard isUserSignedIn() else {completion(FirebaseServiceError.noUserConnected); return}
        
        completion(stubbedDocumentError)
    }
    
    func checkIfUserAlreadyExist(in collection: String, whereFields fields: [FirestoreCondition], completion: @escaping (Result<[[String : Any]], Error>) -> Void) {
        if let error = stubbedDocumentError {
            completion(.failure(error))
            
        }else{
            completion(.success(([])))
        }
    }
    
    
    func signInUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        if stubbedDocumentError != nil {
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


class ListenerRegistrationStub: NSObject, ListenerRegistration {
    func remove() {
        // Vous pouvez ajouter du code ici si nécessaire pour simuler le retrait de l'écouteur.
    }
}

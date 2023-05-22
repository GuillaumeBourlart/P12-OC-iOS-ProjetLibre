//
//  FirebaseService.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 18/05/2023.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum FirestoreCondition {
    case isEqualTo(String, Any)
    case arrayContains(String, Any)
    case isIn(String, Any)
    
}

enum MyError: Error, Equatable {
    case noUserConnected
    case generalError
    // Autres cas d'erreur...
}



protocol FirestoreServiceProtocol {
    func getDocuments(in collection: String, whereFields fields: [FirestoreCondition], completion: @escaping ([[String: Any]]?, Error?) -> Void)
    func getDocument(in collection: String, documentId: String, completion: @escaping ([String: Any]?, Error?) -> Void)
    func setData(in collection: String, documentId: String, data: [String: Any], completion: @escaping (Error?) -> Void)
    func deleteDocument(in collection: String, documentId: String, completion: @escaping (Error?) -> Void)
    func updateDocument(in collection: String, documentId: String, data: [String: Any], completion: @escaping (Error?) -> Void)
}

class FirestoreService: FirestoreServiceProtocol {
    
    
    private let db = Firestore.firestore()
    
    
    func getDocuments(in collection: String, whereFields fields: [FirestoreCondition], completion: @escaping ([[String: Any]]?, Error?) -> Void) {
        var collectionReference:  Query  = db.collection(collection)
            
        for field in fields {
            switch field {
            case .isEqualTo(let key, let value):
                collectionReference = collectionReference.whereField(key, isEqualTo: value)
            case .arrayContains(let key, let value):
                collectionReference = collectionReference.whereField(key, arrayContains: value)
            case .isIn(let key, let value):
                collectionReference = collectionReference.whereField(key, in: value as! [Any])
            }
        }
            
        collectionReference.getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(nil, error)
            } else {
                let documentsData = querySnapshot?.documents.map { $0.data() }
                completion(documentsData, nil)
            }
        }
    }
    
    func getDocument(in collection: String, documentId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
            db.collection(collection).document(documentId).getDocument { (documentSnapshot, error) in
                if let error = error {
                    completion(nil, error)
                } else {
                    let documentData = documentSnapshot?.data()
                    completion(documentData, nil)
                }
            }
        }
    
    func getCompletedGames(currentUserId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let gamesRef = db.collection("games")
        
        gamesRef.whereField("status", isEqualTo: "completed").whereField("players", arrayContains: currentUserId)
            .getDocuments { (querySnapshot, error) in
                // votre code existant...
            }
    }
    
    func setData(in collection: String, documentId: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(documentId).setData(data, completion: completion)
    }
    
    func deleteDocument(in collection: String, documentId: String, completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(documentId).delete(completion: completion)
    }
    
    func updateDocument(in collection: String, documentId: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(documentId).updateData(data, completion: completion)
    }
}



protocol FirebaseAuthServiceProtocol {
    var currentUserID: String? { get }
    func signInUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void)
    func createUser(withEmail email: String, password: String, completion: @escaping (Result<String, Error>) -> Void)
}

class FirebaseAuthService: FirebaseAuthServiceProtocol {
    
    
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    func signInUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authData, error in
            if let error = error {
                completion(.failure(error))
            }else if authData != nil {
                completion(.success(()))
            }
        }
    }
    
    func createUser(withEmail email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authData, error in
            if let error = error {
                completion(.failure(error))
            }else if authData != nil {
                completion(.success((authData?.user.uid)!))
            }
        }
    }
}




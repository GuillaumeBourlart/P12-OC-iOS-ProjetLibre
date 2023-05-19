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
    
}


protocol FirestoreServiceProtocol {
    func getDocuments(in collection: String, whereFields fields: [FirestoreCondition], completion: @escaping (QuerySnapshot?, Error?) -> Void)
    func getDocument(in collection: String, documentId: String, completion: @escaping (DocumentSnapshot?, Error?) -> Void)
    func setData(in collection: String, documentId: String, data: [String: Any], completion: @escaping (Error?) -> Void)
    func deleteDocument(in collection: String, documentId: String, completion: @escaping (Error?) -> Void)
    func updateDocument(in collection: String, documentId: String, data: [String: Any], completion: @escaping (Error?) -> Void)
    
}

class FirestoreService: FirestoreServiceProtocol {
    
    
    private let db = Firestore.firestore()
    
    
    func getDocuments(in collection: String, whereFields fields: [FirestoreCondition], completion: @escaping (QuerySnapshot?, Error?) -> Void) {
        var collectionReference:  Query  = db.collection(collection)
        
        for field in fields {
            switch field {
            case .isEqualTo(let key, let value):
                collectionReference = collectionReference.whereField(key, isEqualTo: value)
            case .arrayContains(let key, let value):
                collectionReference = collectionReference.whereField(key, arrayContains: value)
            }
        }
        
        collectionReference.getDocuments(completion: completion)
    }
    
    
    
    func getDocument(in collection: String, documentId: String, completion: @escaping (DocumentSnapshot?, Error?) -> Void) {
        db.collection(collection).document(documentId).getDocument(completion: completion)
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
    func signInUser(email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void)
    func createUser(withEmail email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void)
}

class FirebaseAuthService: FirebaseAuthServiceProtocol {
    
    
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    func signInUser(email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password, completion: completion)
    }
    
    func createUser(withEmail email: String, password: String, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password, completion: completion)
    }
}




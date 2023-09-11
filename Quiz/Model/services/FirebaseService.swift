//
//  FirebaseService.swift
//  Quiz
//
//  Created by Guillaume Bourlart on 18/05/2023.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage

// Enum to add condition in firestore requests
enum FirestoreCondition {
    case isEqualTo(String, Any)
    case arrayContains(String, Any)
    case isIn(String, [Any])
}

// Enum to handle errors
enum FirebaseServiceError: Error, Equatable {
    case noDataInResponse
    case failedToMakeURL
    case noUserConnected
}

protocol FirebaseServiceProtocol {
    func getDocuments(in collection: String, whereFields fields: [FirestoreCondition], completion: @escaping (Result<[[String: Any]], Error>) -> Void)
    func getDocument(in collection: String, documentId: String, completion: @escaping (Result<[String: Any], Error>) -> Void)
    func setData(in collection: String, documentId: String, data: [String: Any], completion: @escaping (Error?) -> Void)
    func setDataWithMerge(in collection: String, documentId: String, data: [String: Any], merge: Bool, completion: @escaping (Error?) -> Void)
    func deleteDocument(in collection: String, documentId: String, completion: @escaping (Error?) -> Void)
    func updateDocument(in collection: String, documentId: String, data: [String: Any], completion: @escaping (Error?) -> Void)
    func addDocumentSnapshotListener(in collection: String, documentId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) -> ListenerRegistration?
//    func addCollectionSnapshotListener(in collection: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) -> ListenerRegistration?
    func isUserSignedIn() -> Bool
    func storeData(in folder: String, fileName: String, data: Data, completion: @escaping (Result<String, Error>) -> Void)
        func downloadData(from url: String, completion: @escaping (Result<Data, Error>) -> Void)
    
    var currentUserID: String? { get }
    func signInUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void)
    func createUser(withEmail email: String, password: String, completion: @escaping (Result<String, Error>) -> Void)
    func signOutUser(completion: @escaping (Result<Void, Error>) -> Void)
    func resetPassword(for email: String, completion: @escaping (Result<Void, Error>) -> Void)
}

// Class to handle Firebase services
class FirebaseService: FirebaseServiceProtocol{
    
    private let db = Firestore.firestore() // firestore reference
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid // get current UID
    }
    
    func isUserSignedIn() -> Bool {
        return currentUserID != nil
    }
    
    // Function to get documents data
    func getDocuments(in collection: String, whereFields fields: [FirestoreCondition], completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        
        var collectionReference: Query = db.collection(collection)
        
        for field in fields {
            switch field {
            case .isEqualTo(let key, let value):
                collectionReference = collectionReference.whereField(key, isEqualTo: value)
            case .arrayContains(let key, let value):
                collectionReference = collectionReference.whereField(key, arrayContains: value)
            case .isIn(let key, let value):
                collectionReference = collectionReference.whereField(key, in: value)
            }
        }
        
        collectionReference.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("echec 4")
                completion(.failure(error))
            } else if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                let documentsData = querySnapshot.documents.map {
                    var data = $0.data()
                    data["id"] = $0.documentID
                    return data
                }
                completion(.success(documentsData))
            } else {
                completion(.success([]))
            }
        }
    }
    
    // Function to get document data
    func getDocument(in collection: String, documentId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return}
        
        db.collection(collection).document(documentId).getDocument { (documentSnapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else if let documentData = documentSnapshot?.data(), !documentData.isEmpty {
                var data = documentData
                data["id"] = documentSnapshot?.documentID
                completion(.success(data))
            } else {
                completion(.success([:]))
            }
        }
    }
    
    // Function add snapshot listener to a document
    func addDocumentSnapshotListener(in collection: String, documentId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) -> ListenerRegistration? {
        guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return nil}
        
        let documentReference = db.collection(collection).document(documentId)
        let listener = documentReference.addSnapshotListener { documentSnapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let documentData = documentSnapshot?.data(), !documentData.isEmpty {
                var data = documentData
                data["id"] = documentSnapshot?.documentID
                completion(.success(data))
            } else {
                completion(.failure(FirebaseServiceError.noDataInResponse))
            }
        }
        return listener
    }
    
//    // Function to add collection snaphot to a collection
//    func addCollectionSnapshotListener(in collection: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) -> ListenerRegistration? {
//        guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return nil}
//
//        let collectionReference = db.collection(collection)
//        let listener = collectionReference.addSnapshotListener { querySnapshot, error in
//            if let error = error {
//                completion(.failure(error))
//            } else if let documents = querySnapshot?.documents, !documents.isEmpty {
//                let documentsData = documents.map { document in
//                    var data = document.data()
//                    data["id"] = document.documentID
//                    return data
//                }
//                completion(.success(documentsData))
//            } else {
//                completion(.failure(FirebaseServiceError.noDataInResponse))
//            }
//        }
//        return listener
//    }
    
    
    // Function set Data in a document
    func setData(in collection: String, documentId: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        guard isUserSignedIn() else {completion(FirebaseServiceError.noUserConnected); return}
        
        db.collection(collection).document(documentId).setData(data, completion: completion)
    }
    // Function to merge data in a document
    func setDataWithMerge(in collection: String, documentId: String, data: [String: Any], merge: Bool = false, completion: @escaping (Error?) -> Void) {
        guard isUserSignedIn() else {completion(FirebaseServiceError.noUserConnected); return}
        
        db.collection(collection).document(documentId).setData(data, merge: merge, completion: completion)
    }
    // Function to delete a document from it's ID
    func deleteDocument(in collection: String, documentId: String, completion: @escaping (Error?) -> Void) {
        guard isUserSignedIn() else {completion(FirebaseServiceError.noUserConnected); return}
        
        db.collection(collection).document(documentId).delete(completion: completion)
    }
    // Function to update a document from it's ID
    func updateDocument(in collection: String, documentId: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        guard isUserSignedIn() else {completion(FirebaseServiceError.noUserConnected); return}
        
        db.collection(collection).document(documentId).updateData(data, completion: completion)
    }
    func storeData(in folder: String, fileName: String, data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return}
        
            let storageRef = Storage.storage().reference().child(folder).child(fileName)
            storageRef.putData(data, metadata: nil) { (metadata, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Get URL image
                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    if let downloadURL = url {
                        completion(.success(downloadURL.absoluteString))
                    }
                }
            }
        }

        func downloadData(from url: String, completion: @escaping (Result<Data, Error>) -> Void) {
            guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return}
            
            guard let imageURL = URL(string: url) else {
                completion(.failure(FirebaseServiceError.failedToMakeURL))
                return
            }

            SDWebImageDownloader.shared.downloadImage(with: imageURL) { (image, data, error, _) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(data ?? Data()))
                }
            }
        }
    // Function to sign a user
    func signInUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        Auth.auth().signIn(withEmail: email, password: password) { authData, error in
            if let error = error {
                completion(.failure(error))
            } else if authData != nil {
                completion(.success(()))
            }
        }
    }
    // Function to create a user
    func createUser(withEmail email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        Auth.auth().createUser(withEmail: email, password: password) { authData, error in
            if let error = error {
                completion(.failure(error))
            } else if authData != nil {
                completion(.success((authData?.user.uid)!))
            }
        }
    }
    // Function to sign out user
    func signOutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        guard isUserSignedIn() else {completion(.failure(FirebaseServiceError.noUserConnected)); return}
        
        do {
            try Auth.auth().signOut()
            completion(.success(()))
        } catch let error {
            completion(.failure(error))
        }
    }
    
    // Function to reset password
    func resetPassword(for email: String, completion: @escaping (Result<Void, Error>) -> Void){
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
                // Send verification email
                Auth.auth().currentUser?.sendEmailVerification { (error) in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    
    
}




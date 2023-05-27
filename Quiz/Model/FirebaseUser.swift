//
//  firebaseUser.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage


// FirebaseUser est une classe qui gère les opérations liées aux utilisateurs dans Firebase
class FirebaseUser {
    
    static let shared = FirebaseUser()
    
    var currentUserId: String? { return firebaseService.currentUserID }
    
    private var firebaseService: FirebaseServiceProtocol
    
    init(firebaseService: FirebaseServiceProtocol = FirebaseService()) {
        self.firebaseService = firebaseService
    }
    
    var userInfo: aUser?
    var friendGroups: [FriendGroup]?
    var userQuizzes: [Quiz]?
    var History: [GameData]?
    
    // Fonction pour connecter un utilisateur
    func signInUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        firebaseService.signInUser(email: email, password: password) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success():
                self.getUserInfo() { result in
                    switch result {
                    case .success(): completion(.success(()))
                    case .failure(let error): completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // Fonction pour créer un utilisateur
    func createUser(email: String, password: String, pseudo: String, firstName: String, lastName: String, birthDate: Date, completion: @escaping (String?, Error?) -> Void) {
        
        // Vérifiez si le nom d'utilisateur est déjà utilisé
        let conditions: [FirestoreCondition] = [.isEqualTo("username", pseudo)]
        firebaseService.getDocuments(in: "users", whereFields: conditions) { (querySnapshot, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let querySnapshot = querySnapshot, querySnapshot.isEmpty else {
                completion(nil, MyError.usernameAlreadyUsed)
                return
            }
            
            // Créez un nouvel utilisateur
            self.firebaseService.createUser(withEmail: email, password: password) { result in
                switch result {
                case .failure(let error): completion(nil, error)
                case .success(let uid):
                    let birthDateTimestamp = Timestamp(date: birthDate)
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    
                    let inscriptionDate = Timestamp(date: Date())
                    
                    let userData: [String: Any] = [
                        "id": uid,
                        "username": pseudo,
                        "email": email,
                        "first_name": firstName,
                        "last_name": lastName,
                        "birth_date": birthDateTimestamp,
                        "inscription_date": inscriptionDate,
                        "rank": 1,
                        "points": 0,
                        "invites": [String](),
                        "profile_picture": "binary data of the picture",
                        "friends": [String](),
                        "friendRequests": [String:Any]()
                    ]
                    self.firebaseService.setData(in: "users", documentId: uid, data: userData) { error in
                        if let error = error {
                            completion(nil, error)
                        } else {
                            completion(uid, nil)
                        }
                    }
                }
            }
        }
    }
    
    func getUserInfo(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        firebaseService.getDocument(in: "users", documentId: currentUserId) { (userData, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = userData else {
                completion(.failure(MyError.documentDoesntExist))
                return
            }
            
            let convertedDataWithDate = Game.shared.convertTimestampsToDate(in: data)
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: convertedDataWithDate, options: [])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let user = try decoder.decode(aUser.self, from: jsonData)
                self.userInfo = user
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getUserQuizzes(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        let conditions: [FirestoreCondition] = [.isEqualTo("creator", currentUserId)]
        firebaseService.getDocuments(in: "quizzes", whereFields: conditions) { quizzesData, error in
            if let error = error {
                completion(.failure(error))
            } else if let quizzesData = quizzesData {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: quizzesData, options: [])
                    let decoder = JSONDecoder()
                    let quizzes = try decoder.decode([Quiz].self, from: jsonData)
                    self.userQuizzes = quizzes
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.success(())) // no quizzes found
            }
        }
    }
    
    func getUserGroups(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        let conditions: [FirestoreCondition] = [.isEqualTo("creator", currentUserId)]
        firebaseService.getDocuments(in: "groups", whereFields: conditions) { groupsData, error in
            if let error = error {
                completion(.failure(error))
                return
            } else if let groupsData = groupsData {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: groupsData, options: [])
                    let decoder = JSONDecoder()
                    let groups = try decoder.decode([FriendGroup].self, from: jsonData)
                    self.friendGroups = groups
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func saveProfilImage(data: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("profile_picture/\(currentUserId!)")
        
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        storageRef.putData(data, metadata: metaData) { metaData, error in
            if let error = error {
                completion(.failure(error))
            } else {
                storageRef.downloadURL { url, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let url = url {
                        self.firebaseService.updateDocumentWithImageUrl(in: "users", documentId: self.currentUserId!, imageUrl: url) { result in
                            switch result {
                            case .failure(let error): print(error)
                            case .success(let url): print("updated with \(url)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateUsername(){
        
    }
    
    //-----------------------------------------------------------------------------------
    //                                 FRIENDS
    //-----------------------------------------------------------------------------------
    
    func fetchFriends() -> [String] {
        return self.userInfo?.friends ?? []
    }
    
    func sendFriendRequest(username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        let conditions: [FirestoreCondition] = [.isEqualTo("username", username)]
        firebaseService.getDocuments(in: "users", whereFields: conditions) { (documentsData, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let friendDocumentData = documentsData?.first, friendDocumentData["id"] != nil {
                let friendID = friendDocumentData["id"] as! String // Supposant que l'ID est stocké sous la clé "id"
                
                if friendID == currentUserId {
                    completion(.failure(MyError.cantAddYourself))
                    return
                }
                
                if self.userInfo?.friends.contains(friendID) == true {
                    completion(.failure(MyError.alreadyFriend))
                    return
                }
                
                if let friendRequests = self.userInfo?.friendRequests, friendRequests.keys.contains(friendID) {
                    completion(.failure(MyError.alreadySentInvite))
                    return
                }
                
                let friendRequest = aUser.FriendRequest(status: "sent", date: Date())
                let sentRequestData: [String: Any] = [
                    "friendRequests": [
                        friendID: [
                            "status": "sent",
                            "date": Timestamp(date: Date())
                        ] as [String : Any]
                    ]
                ]
                
                let receivedRequestData: [String: Any] = [
                    "friendRequests": [
                        currentUserId: [
                            "status": "received",
                            "date": Timestamp(date: Date())
                        ] as [String : Any]
                    ]
                ]
                
                self.firebaseService.updateDocument(in: "users", documentId: friendID, data: receivedRequestData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.firebaseService.updateDocument(in: "users", documentId: currentUserId, data: sentRequestData) { error in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                self.userInfo?.friendRequests[friendID] = friendRequest
                                completion(.success(()))
                            }
                        }
                    }
                }
            } else {
                completion(.failure(MyError.userNotFound))
            }
        }
    }
    
    
    func fetchFriendRequests() -> [String]{
        let friendRequestsDict = self.userInfo?.friendRequests ?? [:]
        let sentRequests = friendRequestsDict.filter { $1.status == "received" }
       return Array(sentRequests.keys)
    }
    
    
    func acceptFriendRequest(friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(MyError.noUserConnected)); return }
        
        let data: [String: Any] = ["friends": FieldValue.arrayUnion([friendID]), "friendRequests.\(friendID)": FieldValue.delete()]
        firebaseService.updateDocument(in: "users", documentId: currentUserId, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                let data: [String: Any] = ["friends": FieldValue.arrayUnion([currentUserId]), "friendRequests.\(currentUserId)": FieldValue.delete()]
                self.firebaseService.updateDocument(in: "users", documentId: friendID, data: data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    
    func rejectFriendRequest(friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(MyError.noUserConnected)); return }
        
        let data: [String: Any] = ["friendRequests.\(friendID)": FieldValue.delete()]
        firebaseService.updateDocument(in: "users", documentId: currentUserId, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    
    func removeFriend(friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(MyError.noUserConnected)); return }
        
        let data: [String: Any] = ["friends": FieldValue.arrayRemove([friendID])]
        firebaseService.updateDocument(in: "users", documentId: currentUserId, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                let data: [String: Any] = ["friends": FieldValue.arrayRemove([currentUserId])]
                self.firebaseService.updateDocument(in: "users", documentId: friendID, data: data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        if let index = self.userInfo?.friends.firstIndex(of: friendID) {
                            self.userInfo?.friends.remove(at: index)
                        }
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    //-----------------------------------------------------------------------------------
    //                                 QUIZZES
    //-----------------------------------------------------------------------------------
    
    func addQuiz(name: String, category_id: String, difficulty: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(MyError.noUserConnected)); return }
        
        let quizID = UUID().uuidString
        
        generateUniqueCode { code, error in
            if let error = error {
                completion(.failure(error))
            } else if let code = code {
                let newQuiz: [String: Any] = [
                    "id": quizID,
                    "name": name,
                    "category_id": category_id,
                    "difficulty": difficulty,
                    "creator": currentUserId,
                    "average_score": 0,
                    "users_completed": 0,
                    "questions": [[String: Any]](),
                    "code": code
                ]
                
                self.firebaseService.setData(in: "quizzes", documentId: quizID, data: newQuiz) { (error) in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        let quiz = Quiz(
                            id: quizID,
                            name: name,
                            category_id: category_id,
                            creator: currentUserId,
                            difficulty: difficulty,
                            questions: [],
                            average_score: 0,
                            users_completed: 0,
                            code: code
                        )
                        self.userQuizzes?.append(quiz)
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // Fonction pour supprimer un quiz
    func deleteQuiz(quiz: Quiz, completion: @escaping (Result<Void, Error>) -> Void) {
        guard (firebaseService.currentUserID) != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        let quizID: String = quiz.id
        firebaseService.deleteDocument(in: "quizzes", documentId: quizID) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                self.userQuizzes?.removeAll { $0.id == quizID }
                completion(.success(()))
            }
        }
    }
    
    func addQuestionToQuiz(quiz: Quiz, question: String, correctAnswer: String, incorrectAnswers: [String], explanation: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        let questionID = UUID().uuidString
        let questionDict: [String: Any] = [
            "question": question,
            "wrong_answers": incorrectAnswers,
            "correct_answer": correctAnswer,
            "explanation": explanation
        ]
        
        firebaseService.updateDocument(in: "quizzes", documentId: quiz.id, data: ["questions.\(questionID)": questionDict]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let quizIndex = self.userQuizzes?.firstIndex(where: { $0.id == quiz.id }) {
                    let newQuestion = UniversalQuestion(id: questionID, category: nil, type: nil, difficulty: nil, question: question, correct_answer: correctAnswer, incorrect_answers: incorrectAnswers, explanation: explanation)
                    self.userQuizzes?[quizIndex].questions.append(newQuestion)
                    completion(.success(()))
                }
            }
        }
    }
    
    func updateQuiz(quizID: String, newName: String, newCategoryID: String, newDifficulty: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        let data = ["name": newName, "category_id": newCategoryID, "difficulty": newDifficulty]
        firebaseService.updateDocument(in: "quizzes", documentId: quizID, data: data) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let quizIndex = self.userQuizzes?.firstIndex(where: { $0.id == quizID }) {
                    self.userQuizzes?[quizIndex].name = newName
                    self.userQuizzes?[quizIndex].category_id = newCategoryID
                    self.userQuizzes?[quizIndex].difficulty = newDifficulty
                    completion(.success(()))
                }
            }
        }
    }
    
    func deleteQuestionFromQuiz(quiz: Quiz, questionText: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        guard let question = quiz.questions.first(where: { $0.question == questionText }) else {
            completion(.failure(MyError.questionNotFound))
            return
        }
        let data = ["questions.\(question.id!)": FieldValue.delete()]
        firebaseService.updateDocument(in: "quizzes", documentId: quiz.id, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let quizIndex = self.userQuizzes?.firstIndex(where: { $0.id == quiz.id }) {
                    if let questionIndex = self.userQuizzes?[quizIndex].questions.firstIndex(where: { $0.id == question.id }) {
                        self.userQuizzes?[quizIndex].questions.remove(at: questionIndex)
                    }
                }
                completion(.success(()))
            }
        }
    }
    
    func updateQuestionInQuiz(quiz: Quiz, oldQuestion: UniversalQuestion, newQuestionText: String, correctAnswer: String, incorrectAnswers: [String], explanation: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        let updatedQuestionDict: [String: Any] = [
            "question": newQuestionText,
            "incorrect_answers": incorrectAnswers,
            "correct_answer": correctAnswer,
            "explanation": explanation
        ]
        
        let updatedQuestion = UniversalQuestion(id: oldQuestion.id, category: oldQuestion.category, type: oldQuestion.type, difficulty: oldQuestion.difficulty, question: newQuestionText, correct_answer: correctAnswer, incorrect_answers: incorrectAnswers, explanation: explanation)
        
        let data = ["questions.\(oldQuestion.id)": updatedQuestionDict]
        firebaseService.updateDocument(in: "quizzes", documentId: quiz.id, data: data){ error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let quizIndex = self.userQuizzes?.firstIndex(where: { $0.id == quiz.id }) {
                    if let questionIndex = self.userQuizzes?[quizIndex].questions.firstIndex(where: { $0.id == oldQuestion.id }) {
                        self.userQuizzes?[quizIndex].questions[questionIndex] = updatedQuestion
                        completion(.success(()))
                    }
                }
                
            }
        }
    }

    //-----------------------------------------------------------------------------------
    //                                 GROUPS
    //-----------------------------------------------------------------------------------
    
    
    func deleteGroup(group: FriendGroup, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {  completion(.failure(MyError.noUserConnected)); return}
        let groupID = group.id
        firebaseService.deleteDocument(in: "groups", documentId: groupID) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                let data = ["friend_groups": FieldValue.arrayRemove([groupID])]
                self.firebaseService.updateDocument(in: "users", documentId: currentUserId, data: data) { (error) in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.friendGroups?.removeAll { $0.id == groupID }
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    func addGroup(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {  completion(.failure(MyError.noUserConnected)); return}
        
        let groupID = UUID().uuidString
        let newGroup: [String: Any] = ["id": groupID,"creator": currentUserId, "name": name,"members": [String]()]
        
        firebaseService.setData(in: "groups", documentId: groupID, data: newGroup) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                let friendGroup = FriendGroup(id: groupID, creator: currentUserId, name: name, members: [])
                self.friendGroups?.append(friendGroup)
                completion(.success(()))
            }
        }
    }
    
    func updateGroupName(groupID: String, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else {completion(.failure(MyError.noUserConnected)); return}
        let data = ["name": newName]
        firebaseService.updateDocument(in: "groups", documentId: groupID, data: data) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == groupID }) {
                    self.friendGroups?[groupIndex].name = newName
                    completion(.success(()))
                }else{
                    completion(.failure(MyError.generalError))
                }
            }
        }
    }
    
    func addNewMembersToGroup(group: FriendGroup, newMembers: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        var updatedMembers = group.members
        for member in newMembers {
            updatedMembers.append(member)
        }
        
        let data = ["members": updatedMembers]
        firebaseService.updateDocument(in: "groups", documentId: group.id, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == group.id }) {
                    self.friendGroups?[groupIndex].members = updatedMembers
                    completion(.success(()))
                }
                
            }
        }
    }
    
    func removeMemberFromGroup(group: FriendGroup, memberId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        let data = ["members": FieldValue.arrayRemove([memberId])]
        firebaseService.updateDocument(in: "groups", documentId: group.id, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Mettre à jour friendGroups en supprimant le membre
                if let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == group.id }) {
                    // Supprimer le membre du groupe
                    if let memberIndex = self.friendGroups?[groupIndex].members.firstIndex(of: memberId) {
                        self.friendGroups?[groupIndex].members.remove(at: memberIndex)
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    func generateUniqueCode(completion: @escaping (String?, Error?) -> Void) {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let codeLength = 6
        let uniqueCode = String((0..<codeLength).map { _ in characters.randomElement()! })
        
        let conditions: [FirestoreCondition] = [.isEqualTo("code", uniqueCode)]
        firebaseService.getDocuments(in: "quizzes", whereFields: conditions) { (quizzesData, error) in
            if let error = error {
                completion(nil, error)
            } else {
                if quizzesData?.isEmpty == true {
                    // Le code est unique pour les quiz
                    completion(uniqueCode, nil)
                } else {
                    // Le code existe déjà pour les quiz, générer un nouveau code
                    self.generateUniqueCode(completion: completion)
                }
            }
        }
    }
    
}

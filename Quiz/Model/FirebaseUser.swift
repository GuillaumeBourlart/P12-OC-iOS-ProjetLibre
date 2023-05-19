//
//  firebaseUser.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore



// FirebaseUser est une classe qui gère les opérations liées aux utilisateurs dans Firebase
class FirebaseUser {
    
    
    static let shared = FirebaseUser()
    
    private let db = Firestore.firestore()
    private var currentUserId: String? { return Auth.auth().currentUser?.uid }
    
    private var firestoreService: FirestoreServiceProtocol
    private var firebaseAuthService: FirebaseAuthServiceProtocol
    
    init(firestoreService: FirestoreServiceProtocol = FirestoreService(),
         firebaseAuthService: FirebaseAuthServiceProtocol = FirebaseAuthService()) {
        self.firestoreService = firestoreService
        self.firebaseAuthService = firebaseAuthService
    }
    
    var userInfo: User?
    var friendGroups: [FriendGroup]?
    var userQuizzes: [Quiz]?
    var History: [GameData]?
    
    // Fonction pour connecter un utilisateur
    func signInUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        firebaseAuthService.signInUser(email: email, password: password) { authResult, error in
            if let error = error {
                print("Error signing in user: \(error.localizedDescription)")
                completion(.failure(error))
            } else if authResult != nil {
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
    func createUser(email: String, password: String, pseudo: String, firstName: String, lastName: String, birthDate: Date, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        
        // Vérifiez si le nom d'utilisateur est déjà utilisé
        let conditions: [FirestoreCondition] = [.isEqualTo("username", pseudo)]
        firestoreService.getDocuments(in: "users", whereFields: conditions) { (querySnapshot, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let querySnapshot = querySnapshot, querySnapshot.isEmpty else {
                completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ce nom d'utilisateur est déjà utilisé."]))
                return
            }
            
            // Créez un nouvel utilisateur
            self.firebaseAuthService.createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let user = authResult?.user else {
                    completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Une erreur s'est produite lors de la création de l'utilisateur."]))
                    return
                }
                let birthDateTimestamp = Timestamp(date: birthDate)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                let inscriptionDate = Timestamp(date: Date())
                
                let userData: [String: Any] = [
                    "id": user.uid,
                    "username": pseudo,
                    "email": email,
                    "first_name": firstName,
                    "last_name": lastName,
                    "birth_date": birthDateTimestamp,
                    "inscription_date": inscriptionDate,
                    "rank": 1,
                    "points": 0,
                    "profile_picture": "binary data of the picture",
                    "friends": [String](),
                    "friend_groups": [String](),
                    "games": [String](),
                    "created_quizzes": [String](),
                    "friendRequests": [String:Any]()
                ]
                self.firestoreService.setData(in: "users", documentId: user.uid, data: userData) { error in
                    if let error = error {
                        print("Error adding user document: \(error.localizedDescription)")
                    } else {
                        print("User document added with ID: \(user.uid)")
                    }
                }
                
                completion(authResult, nil)
            }
        }
    }
    
    func getUserInfo(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        firestoreService.getDocument(in: "users", documentId: currentUserId) { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User document does not exist."])))
                return
            }
            
            let convertedDataWithDate = Game.shared.convertTimestampsToDate(in: data)
            print("printsssssssssss")
            print(data)
            print(convertedDataWithDate)
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: convertedDataWithDate, options: [])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let user = try decoder.decode(User.self, from: jsonData)
                self.userInfo = user
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getUserQuizzes(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        let userRef = self.db.collection("users").document(currentUserId)
        
        userRef.getDocument { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            } else if let data = snapshot?.data(),
                      let createdQuizzes = data["created_quizzes"] as? [String],
                      !createdQuizzes.isEmpty {
                
                let quizzesRef = self.db.collection("quizzes")
                let query = quizzesRef.whereField(FieldPath.documentID(), in: createdQuizzes)
                
                query.getDocuments { (querySnapshot, error) in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    var quizzes: [Quiz] = []
                    
                    for document in querySnapshot?.documents ?? [] {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: document.data(), options: [])
                            let decoder = JSONDecoder()
                            var quiz = try decoder.decode(Quiz.self, from: jsonData)
                            quiz.id = document.documentID
                            quizzes.append(quiz)
                        } catch {
                            completion(.failure(error))
                            return
                        }
                    }
                    self.userQuizzes = quizzes
                    completion(.success(()))
                }
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getUserGroups(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        let userRef = self.db.collection("users").document(currentUserId)
        userRef.getDocument { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data(), let friendGroups = data["friend_groups"] as? [String], !friendGroups.isEmpty else {
                completion(.success(()))
                return
            }
            
            let groupsRef = self.db.collection("groups")
            let query = groupsRef.whereField(FieldPath.documentID(), in: friendGroups)
            
            query.getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                var groups: [FriendGroup] = []
                
                for document in querySnapshot?.documents ?? [] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: document.data(), options: [])
                        let decoder = JSONDecoder()
                        var group = try decoder.decode(FriendGroup.self, from: jsonData)
                        group.id = document.documentID
                        groups.append(group)
                    } catch {
                        completion(.failure(error))
                        return
                    }
                }
                self.friendGroups = groups
                completion(.success(()))
            }
        }
    }
    
    
    //-----------------------------------------------------------------------------------
    //                                 FRIENDS
    //-----------------------------------------------------------------------------------
    
    
    
    func fetchFriends() -> [String]? {
        guard firebaseAuthService.currentUserID != nil else { print("Aucun utilisateur connecté"); return nil}
        guard self.userInfo != nil else { return [] }
        
        
        return self.userInfo?.friends ?? []
    }
    
    func sendFriendRequest(username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        
        let conditions: [FirestoreCondition] = [.isEqualTo("username", username)]
        firestoreService.getDocuments(in: "users", whereFields: conditions) { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let friendDocument = querySnapshot?.documents.first {
                let friendID = friendDocument.documentID
                
                if friendID == currentUserId {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Vous ne pouvez pas vous ajouter en tant qu'ami"])))
                    return
                }
                
                if self.userInfo?.friends.contains(friendID) == true {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "L'utilisateur est déjà un ami"])))
                    return
                }
                
                if let friendRequests = self.userInfo?.friendRequests, friendRequests.keys.contains(friendID) {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Une demande d'ami a déjà été envoyée"])))
                    return
                }
                
                let friendRequest = User.FriendRequest(status: "sent", date: Date())
                
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
                
                
                self.firestoreService.updateDocument(in: "users", documentId: friendID, data: receivedRequestData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.firestoreService.updateDocument(in: "users", documentId: currentUserId, data: sentRequestData) { error in
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
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Utilisateur introuvable"])))
            }
        }
    }
    
    
    func fetchFriendRequests() -> [String]? {
        guard firebaseAuthService.currentUserID != nil else { print("Aucun utilisateur connecté"); return  nil}
        
        let friendRequestsDict = FirebaseUser.shared.userInfo?.friendRequests ?? [:]
        let sentRequests = friendRequestsDict.filter { $1.status == "received" }
        return Array(sentRequests.keys)
    }
    
    
    func acceptFriendRequest(friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        
        
        let dataa: [String: Any] = ["friends": FieldValue.arrayUnion([friendID]), "friendRequests.\(friendID)": FieldValue.delete()]
        firestoreService.updateDocument(in: "users", documentId: currentUserId, data: dataa) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                
                let dataa: [String: Any] = ["friends": FieldValue.arrayUnion([currentUserId]), "friendRequests.\(currentUserId)": FieldValue.delete()]
                self.firestoreService.updateDocument(in: "users", documentId: friendID, data: dataa) { error in
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
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        let dataa: [String: Any] = ["friendRequests.\(friendID)": FieldValue.delete()]
        firestoreService.updateDocument(in: "users", documentId: currentUserId, data: dataa) { error in
            if let error = error {
                print("Erreur lors du rejet de la demande d'ami : \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    
    func removeFriend(friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        let dataa: [String: Any] = ["friends": FieldValue.arrayRemove([friendID])]
        firestoreService.updateDocument(in: "users", documentId: currentUserId, data: dataa) { error in
            if let error = error {
                print("Erreur lors de la suppression de l'ami : \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                let dataa: [String: Any] = ["friends": FieldValue.arrayRemove([currentUserId])]
                self.firestoreService.updateDocument(in: "users", documentId: friendID, data: dataa) { error in
                    if let error = error {
                        print("Erreur lors de la suppression de l'ami : \(error.localizedDescription)")
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
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        let quizID = UUID().uuidString
        var quizCode = ""
        generateUniqueCode() {code in
            quizCode = code
        }
        
        let newQuiz: [String: Any] = [
            "name": name,
            "category_id": category_id,
            "difficulty": difficulty,
            "creator": currentUserId,
            "average_score": 0,
            "users_completed": 0,
            "questions": [[String: Any]](),
            "code": quizCode
        ]
        firestoreService.setData(in: "quizzes", documentId: quizID, data: newQuiz) { (error) in
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
                    code: quizCode
                )
                
                let data: [String: Any] = [
                    "created_quizzes": FieldValue.arrayUnion([quizID])
                ]
                self.firestoreService.updateDocument(in: "users", documentId: currentUserId, data: data) { (error) in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.userInfo?.created_quizzes.append(quiz.id!)
                        self.userQuizzes?.append(quiz)
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // Fonction pour supprimer un quiz
    func deleteQuiz(quiz: Quiz, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        guard let quizID: String = quiz.id else { return }
        
        firestoreService.deleteDocument(in: "quizzes", documentId: quizID) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                let dataa: [String: Any] = ["created_quizzes": FieldValue.arrayRemove([quizID])]
                self.firestoreService.updateDocument(in: "users", documentId: currentUserId, data: dataa) { (error) in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.userInfo?.created_quizzes.removeAll { $0 == quizID }
                        self.userQuizzes?.removeAll { $0.id == quizID }
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    func addQuestionToQuiz(quiz: Quiz, question: String, correctAnswer: String, incorrectAnswers: [String], explanation: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseAuthService.currentUserID != nil else { print("Aucun utilisateur connecté"); return}
        let questionID = UUID().uuidString
        let questionDict: [String: Any] = [
            "question": question,
            "wrong_answers": incorrectAnswers,
            "correct_answer": correctAnswer,
            "explanation": explanation
        ]
        let newQuestion = UniversalQuestion(id: questionID, category: nil, type: nil, difficulty: nil, question: question, correct_answer: correctAnswer, incorrect_answers: incorrectAnswers, explanation: explanation)
        
        
        firestoreService.updateDocument(in: "quizzes", documentId: quiz.id!, data: ["questions.\(questionID)": questionDict]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let quizIndex = self.userQuizzes?.firstIndex(where: { $0.id == quiz.id }) {
                    self.userQuizzes?[quizIndex].questions.append(newQuestion)
                }
                completion(.success(()))
            }
        }
    }
    
    func updateQuiz(quizID: String, newName: String, newCategoryID: String, newDifficulty: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseAuthService.currentUserID != nil else { print("Aucun utilisateur connecté"); return}
        let data = ["name": newName, "category_id": newCategoryID, "difficulty": newDifficulty]
        firestoreService.updateDocument(in: "quizzes", documentId: quizID, data: data) { (error) in
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
        guard firebaseAuthService.currentUserID != nil else { print("Aucun utilisateur connecté"); return}
        guard let question = quiz.questions.first(where: { $0.question == questionText }) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Question text not found"])))
            return
        }
        let data = ["questions.\(question.id!)": FieldValue.delete()]
        firestoreService.updateDocument(in: "quizzes", documentId: quiz.id!, data: data) { error in
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
        guard firebaseAuthService.currentUserID != nil else { print("Aucun utilisateur connecté"); return}
        let updatedQuestionDict: [String: Any] = [
            "question": newQuestionText,
            "incorrect_answers": incorrectAnswers,
            "correct_answer": correctAnswer,
            "explanation": explanation
        ]
        
        let updatedQuestion = UniversalQuestion(id: oldQuestion.id, category: oldQuestion.category, type: oldQuestion.type, difficulty: oldQuestion.difficulty, question: newQuestionText, correct_answer: correctAnswer, incorrect_answers: incorrectAnswers, explanation: explanation)
        
        let data = ["questions.\(oldQuestion.id)": updatedQuestionDict]
        firestoreService.updateDocument(in: "quizzes", documentId: quiz.id!, data: data){ error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let quizIndex = self.userQuizzes?.firstIndex(where: { $0.id == quiz.id }) {
                    if let questionIndex = self.userQuizzes?[quizIndex].questions.firstIndex(where: { $0.id == oldQuestion.id }) {
                        self.userQuizzes?[quizIndex].questions[questionIndex] = updatedQuestion
                    }
                }
                completion(.success(()))
            }
        }
    }
    
    
    
    //-----------------------------------------------------------------------------------
    //                                 GROUPS
    //-----------------------------------------------------------------------------------
    
    
    func deleteGroup(group: FriendGroup, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        guard let groupID = group.id else { return }
        firestoreService.deleteDocument(in: "groups", documentId: groupID) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Groupe d'amis supprimé avec succès")
                let data = ["friend_groups": FieldValue.arrayRemove([groupID])]
                self.firestoreService.updateDocument(in: "users", documentId: currentUserId, data: data) { (error) in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.userInfo?.friend_groups.removeAll { $0 == groupID }
                        self.friendGroups?.removeAll { $0.id == groupID }
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    func addGroup(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        let groupID = UUID().uuidString
        
        let newGroup: [String: Any] = ["id": groupID,"name": name,"members": [String]()]

        firestoreService.setData(in: "groups", documentId: groupID, data: newGroup) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                let friendGroup = FriendGroup(id: groupID, name: name, members: [])
                
                let data = ["friend_groups": FieldValue.arrayUnion([groupID])]
                self.firestoreService.updateDocument(in: "users", documentId: currentUserId, data: data) { (error) in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.userInfo?.friend_groups.append(groupID)
                        self.friendGroups?.append(friendGroup)
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    func updateGroupName(groupID: String, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseAuthService.currentUserID != nil else { print("Aucun utilisateur connecté"); return}
        let data = ["name": newName]
        firestoreService.updateDocument(in: "groups", documentId: groupID, data: data) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                // Mettre à jour le nom du groupe dans le groupe d'amis local
                if let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == groupID }) {
                    self.friendGroups?[groupIndex].name = newName
                    _ = FriendGroup(id: groupID, name: newName, members: self.friendGroups?[groupIndex].members ?? [String]())
                    completion(.success(()))
                }
            }
        }
    }
    
    func addNewMembersToGroup(group: FriendGroup, newMembers: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseAuthService.currentUserID != nil else { print("Aucun utilisateur connecté"); return}
        // Fusionner les membres existants avec les nouveaux membres
        print("newmembers \(newMembers)")
        var updatedMembers = group.members
        for member in newMembers {
            updatedMembers.append(member)
        }
        print("updated \(updatedMembers)")
        
        // Mettre à jour la base de données Firestore
        let data = ["members": updatedMembers]
        firestoreService.updateDocument(in: "groups", documentId: group.id!, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Mettre à jour friendGroups en ajoutant les nouveaux membres
                if let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == group.id }) {
                    self.friendGroups?[groupIndex].members = updatedMembers
                    print("Nouveaux membres ajoutés avec succès au groupe")
                    completion(.success(()))
                }
                
            }
        }
    }
    
    func removeMemberFromGroup(group: FriendGroup, memberId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseAuthService.currentUserID != nil else { print("Aucun utilisateur connecté"); return}
        
        
        // Supprimer le membre du groupe
        let data = ["members": FieldValue.arrayRemove([memberId])]
        firestoreService.updateDocument(in: "groups", documentId: group.id!, data: data) { error in
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
    
    
    func generateUniqueCode(completion: @escaping (String) -> Void) {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let codeLength = 6
        let uniqueCode = String((0..<codeLength).map { _ in characters.randomElement()! })
        
        
        let conditions: [FirestoreCondition] = [.isEqualTo("code", uniqueCode)]
        firestoreService.getDocuments(in: "quizzes", whereFields: conditions) { (querySnapshot, error) in
            if let error = error {
                print("Erreur lors de la vérification de l'unicité du code dans les quiz : \(error.localizedDescription)")
                completion("") // Vous pouvez gérer cette situation comme vous le souhaitez
            } else {
                if querySnapshot!.documents.isEmpty {
                    // Le code est unique pour les quiz, vérifier maintenant les lobbies
                    let conditions: [FirestoreCondition] = [.isEqualTo("join_code", uniqueCode)]
                    self.firestoreService.getDocuments(in: "lobby", whereFields: conditions) { (querySnapshot, error) in
                        if let error = error {
                            print("Erreur lors de la vérification de l'unicité du code dans les lobbies : \(error.localizedDescription)")
                            completion("") // Vous pouvez gérer cette situation comme vous le souhaitez
                        } else {
                            if querySnapshot!.documents.isEmpty {
                                // Le code est unique pour les lobbies également
                                completion(uniqueCode)
                            } else {
                                // Le code existe déjà dans les lobbies, générer un nouveau code
                                self.generateUniqueCode(completion: completion)
                            }
                        }
                    }
                    
                } else {
                    // Le code existe déjà pour les quiz, générer un nouveau code
                    self.generateUniqueCode(completion: completion)
                }
            }
        }
    }
    
}

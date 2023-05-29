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
        let conditions: [FirestoreCondition] = [.isEqualTo(FirestoreFields.User.username, pseudo)]
        firebaseService.getDocuments(in: FirestoreFields.usersCollection, whereFields: conditions) { (querySnapshot, error) in
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
                        FirestoreFields.id: uid,
                        FirestoreFields.User.username: pseudo,
                        FirestoreFields.User.email: email,
                        FirestoreFields.User.firstName: firstName,
                        FirestoreFields.User.lastName: lastName,
                        FirestoreFields.User.birthDate: birthDateTimestamp,
                        FirestoreFields.User.inscriptionDate: inscriptionDate,
                        FirestoreFields.User.rank: 1,
                        FirestoreFields.User.points: 0,
                        FirestoreFields.User.invites: [String](),
                        FirestoreFields.User.profilePicture: "",
                        FirestoreFields.User.friends: [String](),
                        FirestoreFields.User.friendRequests: [String:Any]()
                    ]
                    self.firebaseService.setData(in: FirestoreFields.usersCollection, documentId: uid, data: userData) { error in
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
        
        firebaseService.getDocument(in: FirestoreFields.usersCollection, documentId: currentUserId) { (userData, error) in
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
        
        let conditions: [FirestoreCondition] = [.isEqualTo(FirestoreFields.creator, currentUserId)]
        firebaseService.getDocuments(in: FirestoreFields.quizzesCollection, whereFields: conditions) { quizzesData, error in
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
        
        let conditions: [FirestoreCondition] = [.isEqualTo(FirestoreFields.creator, currentUserId)]
        firebaseService.getDocuments(in: FirestoreFields.groupsCollection, whereFields: conditions) { groupsData, error in
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
    
    func saveProfilImage(data: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        self.firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: [FirestoreFields.User.profilePicture: data]) { error in
            if let error = error {
                completion(.failure(error))
            }
            completion(.success(()))
        }
    }
    
    func updateUsername(username: String, completion: @escaping (Result<Void, Error>) -> Void){
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        self.firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: [FirestoreFields.User.username: username]) { error in
            if let error = error {
                completion(.failure(error))
            }
            completion(.success(()))
        }
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
        
        let conditions: [FirestoreCondition] = [.isEqualTo(FirestoreFields.User.username, username)]
        firebaseService.getDocuments(in: FirestoreFields.usersCollection, whereFields: conditions) { (documentsData, error) in
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
                    FirestoreFields.User.friendRequests: [
                        friendID: [
                            FirestoreFields.status: "sent",
                            FirestoreFields.date: Timestamp(date: Date())
                        ] as [String : Any]
                    ]
                ]
                
                let receivedRequestData: [String: Any] = [
                    FirestoreFields.User.friendRequests: [
                        currentUserId: [
                            FirestoreFields.status: "received",
                            FirestoreFields.date: Timestamp(date: Date())
                        ] as [String : Any]
                    ]
                ]
                
                self.firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: friendID, data: receivedRequestData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: sentRequestData) { error in
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
        
        let data: [String: Any] = [
            FirestoreFields.User.friends: FieldValue.arrayUnion([friendID]),
            "\(FirestoreFields.User.friendRequests).\(friendID)": FieldValue.delete()
        ]
        
        firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                let data: [String: Any] = [
                    FirestoreFields.User.friends: FieldValue.arrayUnion([currentUserId]),
                    "\(FirestoreFields.User.friendRequests).\(currentUserId)": FieldValue.delete()
                ]
                
                self.firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: friendID, data: data) { error in
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
        
        let data: [String: Any] = [
            "\(FirestoreFields.User.friendRequests).\(friendID)": FieldValue.delete()
        ]
        
        firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    
    func removeFriend(friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(MyError.noUserConnected)); return }
        
        let data: [String: Any] = [
            FirestoreFields.User.friends: FieldValue.arrayRemove([friendID])
        ]
        firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                let data: [String: Any] = [
                    FirestoreFields.User.friends: FieldValue.arrayRemove([currentUserId])
                ]
                
                self.firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: friendID, data: data) { error in
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
                    FirestoreFields.id: quizID,
                    FirestoreFields.Quiz.name: name,
                    FirestoreFields.Quiz.categoryId: category_id,
                    FirestoreFields.Quiz.difficulty: difficulty,
                    FirestoreFields.creator: currentUserId,
                    FirestoreFields.Quiz.averageScore: 0,
                    FirestoreFields.Quiz.usersCompleted: 0,
                    FirestoreFields.Quiz.questions: [[String: Any]](),
                    FirestoreFields.Quiz.code: code
                ]
                
                self.firebaseService.setData(in: FirestoreFields.quizzesCollection, documentId: quizID, data: newQuiz) { (error) in
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
    
    func deleteQuiz(quiz: Quiz, completion: @escaping (Result<Void, Error>) -> Void) {
        guard (firebaseService.currentUserID) != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        let quizID: String = quiz.id
        firebaseService.deleteDocument(in: FirestoreFields.quizzesCollection, documentId: quizID) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                self.userQuizzes?.removeAll { $0.id == quizID }
                completion(.success(()))
            }
        }
    }
    
    func addQuestionToQuiz(quiz: Quiz, question: String, correctAnswer: String, wrongAnswers: [String], explanation: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        let questionID = UUID().uuidString
        let questionsField = "\(FirestoreFields.Quiz.questions).\(questionID)"
        
        let questionDict: [String: Any] = [
            FirestoreFields.Question.question: question,
            FirestoreFields.Question.incorrectAnswers: wrongAnswers,
            FirestoreFields.Question.correctAnswer: correctAnswer,
            FirestoreFields.Question.explanation: explanation
        ]
        
        firebaseService.updateDocument(in: FirestoreFields.quizzesCollection, documentId: quiz.id, data: [questionsField: questionDict]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let quizIndex = self.userQuizzes?.firstIndex(where: { $0.id == quiz.id }) {
                    let newQuestion = UniversalQuestion(id: questionID, category: nil, type: nil, difficulty: nil, question: question, correct_answer: correctAnswer, incorrect_answers: wrongAnswers, explanation: explanation)
                    self.userQuizzes?[quizIndex].questions.append(newQuestion)
                    completion(.success(()))
                }
            }
        }
    }
    
    func updateQuiz(quizID: String, newName: String, newCategoryID: String, newDifficulty: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        let data = [
            FirestoreFields.Quiz.name: newName,
            FirestoreFields.Quiz.categoryId: newCategoryID,
            FirestoreFields.Quiz.difficulty: newDifficulty
        ]
        
        firebaseService.updateDocument(in: FirestoreFields.quizzesCollection, documentId: quizID, data: data) { (error) in
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
        let data = [
            "\(FirestoreFields.Quiz.questions).\(question.id!)": FieldValue.delete()
        ]
        
        firebaseService.updateDocument(in: FirestoreFields.quizzesCollection, documentId: quiz.id, data: data) { error in
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
            FirestoreFields.Question.question: newQuestionText,
            FirestoreFields.Question.incorrectAnswers: incorrectAnswers,
            FirestoreFields.Question.correctAnswer: correctAnswer,
            FirestoreFields.Question.explanation: explanation
        ]
        
        let updatedQuestion = UniversalQuestion(id: oldQuestion.id, category: oldQuestion.category, type: oldQuestion.type, difficulty: oldQuestion.difficulty, question: newQuestionText, correct_answer: correctAnswer, incorrect_answers: incorrectAnswers, explanation: explanation)
        
        let data = ["\(FirestoreFields.Quiz.questions).\(oldQuestion.id)": updatedQuestionDict]
        firebaseService.updateDocument(in: FirestoreFields.quizzesCollection, documentId: quiz.id, data: data){ error in
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
        firebaseService.deleteDocument(in: FirestoreFields.groupsCollection, documentId: groupID) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                
                self.friendGroups?.removeAll { $0.id == groupID }
                completion(.success(()))
                
            }
        }
    }
    
    func addGroup(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {  completion(.failure(MyError.noUserConnected)); return}
        
        let groupID = UUID().uuidString
        let newGroup: [String: Any] = [FirestoreFields.id: groupID, FirestoreFields.creator: currentUserId, FirestoreFields.Group.name: name, FirestoreFields.Group.members: [String]()]
        
        firebaseService.setData(in: FirestoreFields.groupsCollection, documentId: groupID, data: newGroup) { (error) in
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
        let data = [FirestoreFields.Group.name: newName]
        firebaseService.updateDocument(in: FirestoreFields.groupsCollection, documentId: groupID, data: data) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == groupID }) {
                    self.friendGroups?[groupIndex].name = newName
                    completion(.success(()))
                } else {
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
        
        let data = [FirestoreFields.Group.members: updatedMembers]
        firebaseService.updateDocument(in: FirestoreFields.groupsCollection, documentId: group.id, data: data) { error in
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
        
        let data = [FirestoreFields.Group.members: FieldValue.arrayRemove([memberId])]
        firebaseService.updateDocument(in: FirestoreFields.groupsCollection, documentId: group.id, data: data) { error in
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
        
        let conditions: [FirestoreCondition] = [.isEqualTo(FirestoreFields.Quiz.code, uniqueCode)]
        firebaseService.getDocuments(in: FirestoreFields.quizzesCollection, whereFields: conditions) { (quizzesData, error) in
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

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
import SDWebImage


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
    
    
    func signOut(completion: @escaping (Result<Void, Error>) -> Void ) {
        guard let currentUserId = currentUserId else { return }
        firebaseService.signOutUser { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(): completion(.success(()))
            }
        }
    }
    
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
                        FirestoreFields.User.invites: [String: String](),
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
                    } catch let DecodingError.dataCorrupted(context) {
                        print("Data corrupted: ", context)
                        completion(.failure(error!))
                    } catch let DecodingError.keyNotFound(key, context) {
                        print("Key '\(key)' not found: ", context.debugDescription)
                        print("codingPath: ", context.codingPath)
                        completion(.failure(error!))
                    } catch let DecodingError.valueNotFound(value, context) {
                        print("Value '\(value)' not found: ", context.debugDescription)
                        print("codingPath: ", context.codingPath)
                        completion(.failure(error!))
                    } catch let DecodingError.typeMismatch(type, context) {
                        print("Type '\(type)' mismatch: ", context.debugDescription)
                        print("codingPath: ", context.codingPath)
                        completion(.failure(error!))
                    } catch {
                        print("error: ", error)
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
    
    func saveImageInStorage(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        // Générer un nom de fichier unique pour l'image
        let imageFileName = "\(currentUserId).jpg"
        
        // Référence à l'emplacement de stockage dans Firebase Storage
        let storageRef = Storage.storage().reference().child("profile_images").child(imageFileName)
        
        // Mettre à jour le code pour télécharger l'image dans Firebase Storage
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Récupérer l'URL de téléchargement de l'image
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
    
    func saveProfileImage(url: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        self.firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: [FirestoreFields.User.profilePicture: url]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func downloadProfileImageFromURL(url: String, completion: @escaping (Data?) -> Void) {
        guard let imageURL = URL(string: url) else {
            // Gestion des erreurs
            print("Invalid image URL")
            completion(nil)
            return
        }
        
        SDWebImageDownloader.shared.downloadImage(with: imageURL) { (image, data, error, _) in
            if let error = error {
                // Gestion des erreurs
                print("Error downloading profile image:", error)
                completion(nil)
                return
            }
            
            completion(data)
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
    
    func fetchFriends(completion: @escaping ([String: String]?, Error?) -> Void) {
        guard let frinedUIDs = self.userInfo?.friends else {
                completion(nil, MyError.userNotFound) // Provide appropriate error
                return
            }
        var players = [String: String]()
        
        let group = DispatchGroup()

        for friendUID in frinedUIDs {
            group.enter()
            
            fetchUsername(with: friendUID) { result in
                switch result {
                case .failure(let error):
                    print("Error: \(error)")
                case .success(let username):
                    players[friendUID] = username
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print(players)
            completion(players, nil)
        }
    }
    
    func fetchInvites(completion: @escaping ([String: String]?, Error?) -> Void) {
        guard let invites = self.userInfo?.invites else {
                completion(nil, MyError.userNotFound) // Provide appropriate error
                return
            }
        var invitations = [String: String]()
        
        let group = DispatchGroup()

        for (key, value) in invites {
            group.enter()
            
            fetchUsername(with: key) { result in
                switch result {
                case .failure(let error):
                    print("Error: \(error)")
                case .success(let username):
                    invitations[username] = value
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(invitations, nil)
        }
    }
    
    func fetchUsername(with uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        firebaseService.getDocument(in: FirestoreFields.usersCollection, documentId: uid) { (documentData, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let documentData = documentData, let username = documentData["username"] as? String {
                completion(.success(username))
            } else {
                completion(.failure(MyError.userNotFound))
            }
        }
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
                let friendID = friendDocumentData["id"] as! String // Supposing the ID is stored under the key "id"
                
                if friendID == currentUserId {
                    completion(.failure(MyError.cantAddYourself))
                    return
                }
                
                // Create friend request data
                let friendRequestData: [String: Any] = [
                    FirestoreFields.User.friendRequests: [
                        friendID: [
                            FirestoreFields.status: "sent",
                            FirestoreFields.date: Timestamp(date: Date())
                        ] as [String : Any]
                    ]
                ]
                
                // Send friend request
                self.firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: friendRequestData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            } else {
                completion(.failure(MyError.userNotFound))
            }
        }
    }
    
    
    func fetchFriendRequests(completion: @escaping ([String: String]?, Error?) -> Void){
        guard let friendRequests = self.userInfo?.friendRequests else {
                completion(nil, MyError.userNotFound) // Provide appropriate error
                return
            }
        
        var players = [String: String]()
        
        let group = DispatchGroup()
        let receivedRequests = friendRequests.filter { $0.value.status == "received" }
        let keysArray = Array(receivedRequests.keys)
        for friendUID in keysArray {
            group.enter()
            
            fetchUsername(with: friendUID) { result in
                switch result {
                case .failure(let error):
                    print("Error: \(error)")
                case .success(let username):
                    players[friendUID] = username
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(players, nil)
        }
    }
    
    
    func acceptFriendRequest(friendID: String, friendUsername: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(MyError.noUserConnected)); return }
        
        let data: [String: Any] = [
            "\(FirestoreFields.User.friends)": [friendID],
            "\(FirestoreFields.User.friendRequests).\(friendID)": FieldValue.delete()
        ]
        
        firebaseService.setDataWithMerge(in: FirestoreFields.usersCollection, documentId: currentUserId, data: data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
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
            "\(FirestoreFields.User.friends)": FieldValue.arrayRemove([friendID])
        ]

        firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
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
                    FirestoreFields.Quiz.name: name,
                    FirestoreFields.Quiz.categoryId: category_id,
                    FirestoreFields.Quiz.difficulty: difficulty,
                    FirestoreFields.creator: currentUserId,
                    FirestoreFields.Quiz.averageScore: 0,
                    FirestoreFields.Quiz.usersCompleted: 0,
                    FirestoreFields.Quiz.questions: [String: Any](),
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
                            questions: [:],
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
    
    func addQuestionToQuiz(quiz: Quiz, questionText: String, correctAnswer: String, incorrectAnswers: [String], explanation: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else {
            completion(.failure(MyError.noUserConnected));
            return
        }
        
        let questionID = UUID().uuidString
        let questionsField = "\(FirestoreFields.Quiz.questions).\(questionID)"
        
        let questionDict: [String: Any] = [
            FirestoreFields.Question.question: questionText,
            FirestoreFields.Question.incorrectAnswers: incorrectAnswers,
            FirestoreFields.Question.correctAnswer: correctAnswer,
            FirestoreFields.Question.explanation: explanation,
            FirestoreFields.Question.category: "Custom",
            FirestoreFields.Question.type: "Custom",
            FirestoreFields.Question.difficulty: "Custom"
        ]
        
        firebaseService.updateDocument(in: FirestoreFields.quizzesCollection, documentId: quiz.id, data: [questionsField: questionDict]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let quizIndex = self.userQuizzes?.firstIndex(where: { $0.id == quiz.id }) {
                    let newQuestion = UniversalQuestion(id: questionID, category: "Custom", type: "Custom", difficulty: "Custom", question: questionText, correct_answer: correctAnswer, incorrect_answers: incorrectAnswers, explanation: explanation)
                    self.userQuizzes?[quizIndex].questions[questionID] = newQuestion
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
    
    func deleteQuestionFromQuiz(quiz: Quiz, questionId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else {
            completion(.failure(MyError.noUserConnected));
            return
        }
        guard quiz.questions.keys.contains(questionId) else {
            completion(.failure(MyError.questionNotFound))
            return
        }
        let data = [
            "\(FirestoreFields.Quiz.questions).\(questionId)": FieldValue.delete()
        ]
        
        firebaseService.updateDocument(in: FirestoreFields.quizzesCollection, documentId: quiz.id, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let quizIndex = self.userQuizzes?.firstIndex(where: { $0.id == quiz.id }) {
                    self.userQuizzes?[quizIndex].questions.removeValue(forKey: questionId)
                }
                completion(.success(()))
            }
        }
    }
    
    func updateQuestionInQuiz(quiz: Quiz, oldQuestionId: String, newQuestionText: String, correctAnswer: String, incorrectAnswers: [String], explanation: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else {
            completion(.failure(MyError.noUserConnected));
            return
        }
        
        guard let oldQuestion = quiz.questions[oldQuestionId] else {
            completion(.failure(MyError.questionNotFound))
            return
        }
        
        let updatedQuestionDict: [String: Any] = [
            FirestoreFields.Question.question: newQuestionText,
            FirestoreFields.Question.incorrectAnswers: incorrectAnswers,
            FirestoreFields.Question.correctAnswer: correctAnswer,
            FirestoreFields.Question.explanation: explanation,
        ]
        
        let updatedQuestion = UniversalQuestion(id: oldQuestionId, category: oldQuestion.category, type: oldQuestion.type, difficulty: oldQuestion.difficulty, question: newQuestionText, correct_answer: correctAnswer, incorrect_answers: incorrectAnswers, explanation: explanation)
        
        let data = ["\(FirestoreFields.Quiz.questions).\(oldQuestionId)": updatedQuestionDict]
        
        firebaseService.updateDocument(in: FirestoreFields.quizzesCollection, documentId: quiz.id, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let quizIndex = self.userQuizzes?.firstIndex(where: { $0.id == quiz.id }) {
                    self.userQuizzes?[quizIndex].questions[oldQuestionId] = updatedQuestion
                }
                completion(.success(()))
            }
        }
    }
    
    //-----------------------------------------------------------------------------------
    //                                 GROUPS
    //-----------------------------------------------------------------------------------
    
    
    func deleteGroup(group: FriendGroup, completion: @escaping (Result<Void, Error>) -> Void) {
        guard (firebaseService.currentUserID) != nil else {  completion(.failure(MyError.noUserConnected)); return}
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
        let newGroup: [String: Any] = [
            FirestoreFields.creator: currentUserId,
            FirestoreFields.Group.name: name,
            FirestoreFields.Group.members: [String]()
        ]
        
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
                    completion(.failure(MyError.failedToUpdateGroupName))
                }
            }
        }
    }
    
    func addNewMembersToGroup(group: FriendGroup, newMembers: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserID = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        // Assurez-vous d'avoir une référence valide à friendGroups et à l'index du groupe.
        guard let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == group.id }) else {
            completion(.failure(MyError.failedToUpdateGroupMembers))
            return
        }
        
        // Ajouter les nouveaux membres à la liste existante.
        let updatedMembers = (self.friendGroups?[groupIndex].members ?? []) + newMembers
        let data = [FirestoreFields.Group.members: updatedMembers]
        
        firebaseService.setDataWithMerge(in: FirestoreFields.groupsCollection, documentId: group.id, data: data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Mettre à jour la liste locale des membres du groupe.
                self.friendGroups?[groupIndex].members = updatedMembers
                completion(.success(()))
            }
        }
    }
    
    func removeMemberFromGroup(group: FriendGroup, memberId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else {
            completion(.failure(MyError.noUserConnected))
            return
        }

        // Assurez-vous d'avoir une référence valide à friendGroups et à l'index du groupe.
        guard let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == group.id }) else {
            completion(.failure(MyError.failedToRemoveMembersFromGroup))
            return
        }

        // Retirer le membre du tableau des membres.
        let updatedMembers = self.friendGroups?[groupIndex].members.filter { $0 != memberId }

        let data = [FirestoreFields.Group.members: updatedMembers ?? []]
        
        firebaseService.setDataWithMerge(in: FirestoreFields.groupsCollection, documentId: group.id, data: data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Mettre à jour la liste locale des membres du groupe.
                self.friendGroups?[groupIndex].members = updatedMembers ?? []
                completion(.success(()))
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

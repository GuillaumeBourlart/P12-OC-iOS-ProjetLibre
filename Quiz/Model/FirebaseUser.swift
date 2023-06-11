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


// handle action and information concerning user
class FirebaseUser {
    
    static let shared = FirebaseUser()
    var currentUserId: String? { return firebaseService.currentUserID } // get current UID
    private var firebaseService: FirebaseServiceProtocol
    init(firebaseService: FirebaseServiceProtocol = FirebaseService()) {
        self.firebaseService = firebaseService
    }
    var userInfo: aUser? // User's informations
    var friendGroups: [FriendGroup]? // User's groups
    var userQuizzes: [Quiz]? // User's quizzes
    var History: [GameData]? // User's history
    
    // Function to sign out
    func signOut(completion: @escaping (Result<Void, Error>) -> Void ) {
        guard currentUserId != nil else { return }
        firebaseService.signOutUser { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(): completion(.success(()))
            }
        }
    }
    
    // Function to sign out
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
    
    // Function to create user
    func createUser(email: String, password: String, pseudo: String, firstName: String, lastName: String, birthDate: Date, completion: @escaping (String?, Error?) -> Void) {
        
        // Check if username already exist
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
            
            // Create user
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
                        FirestoreFields.User.rank: 1.0,
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
    
    // Function to get user's information
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
    
    // Function to get user's quizzes
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
                    completion(.success(()))
                }
            }
        }
    
    // Function to get user's groups
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
    
    // Function to save user's profile image on Firestore Storage
    func saveImageInStorage(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        let imageFileName = "\(currentUserId).jpg"
        let storageRef = Storage.storage().reference().child("profile_images").child(imageFileName)
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
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
    
    // Function to save Firestore Storage URL of the profile image in Firestore user's document
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
    
    // Function to get Firestore storage Image from URL
    func downloadProfileImageFromURL(url: String, completion: @escaping (Data?) -> Void) {
        guard let imageURL = URL(string: url) else {
            print("Invalid image URL")
            completion(nil)
            return
        }
        
        SDWebImageDownloader.shared.downloadImage(with: imageURL) { (image, data, error, _) in
            if let error = error {
                print("Error downloading profile image:", error)
                completion(nil)
                return
            }
            completion(data)
        }
    }
    
    // Function to save user's new username
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
    
    // Function to display freinds for UID's
    func fetchFriends(completion: @escaping ([String: String]?, Error?) -> Void) {
        guard let frinedUIDs = self.userInfo?.friends else {
                completion(nil, MyError.userNotFound)
                return
            }
        var players = [String: String]()

        getUsernames(with: frinedUIDs) { result in
            switch result {
            case .failure(let error): completion(nil, error)
            case .success(let  friends): players = friends
                completion(players, nil)
            }

        }
    }
    
    // Function to display invites form ID
    func fetchInvites(completion: @escaping ([String: String]?, Error?) -> Void) {
        guard let invites = self.userInfo?.invites else {
            completion(nil, MyError.userNotFound)
            return
        }

        let uids = Array(invites.keys)
        getUsernames(with: uids) { result in
            switch result {
            case .failure(let error):
                completion(nil, error)
            case .success(let usernameDict):
                var invitations = [String: String]()
                for (uid, inviteId) in invites {
                    if let username = usernameDict[uid] {
                        invitations[username] = inviteId
                    }
                }
                completion(invitations, nil)
            }
        }
    }
    
    // Function to get user's username from their UID
    func getUsernames(with uids: [String], completion: @escaping (Result<[String: String], Error>) -> Void) {
        var usernames = [String: String]() // Dictionnaire pour stocker les UID et les usernames correspondants
        let dispatchGroup = DispatchGroup() // Groupe pour gérer les appels asynchrones multiples
        
        for uid in uids {
            dispatchGroup.enter()
            firebaseService.getDocument(in: FirestoreFields.usersCollection, documentId: uid) { (documentData, error) in
                defer { dispatchGroup.leave() }
                if let error = error {
                    print("Failed to fetch user for uid: \(uid), error: \(error)")
                } else if let documentData = documentData, let username = documentData["username"] as? String {
                    usernames[uid] = username
                } else {
                    print("User not found for uid: \(uid)")
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if usernames.isEmpty {
                completion(.failure(MyError.userNotFound))
            } else {
                completion(.success(usernames))
            }
        }
    }
    
    // Function to send Friend request
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
                let friendID = friendDocumentData["id"] as! String
                
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
    
    // Function to display friend requests
    func fetchFriendRequests(completion: @escaping ([String: String]?, Error?) -> Void){
        guard let friendRequests = self.userInfo?.friendRequests else {
                completion(nil, MyError.userNotFound)
                return
            }
        
        var players = [String: String]()
        
        let receivedRequests = friendRequests.filter { $0.value.status == "received" }
        let keysArray = Array(receivedRequests.keys)
        
        getUsernames(with: keysArray) { result in
            switch result {
            case .failure(let error): completion(nil, error)
            case .success(let  requests): players = requests
                completion(players, nil)
            }
        }
    }
    
    // Function to accept a friend  and add him in friends list
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
    
    // Function to reject friend request  and delete friend request
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
    
    // Function to remove a friend from friends list
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
    
    // Function to add/create a new quizz
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
    
    // Function to delete a quiz from quizzes
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
    
    // Function to add Question to a quiz
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
    
    // Function to pdate a quiz from it's quiz iD
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
    
    // Function to delete a question from quizz
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
    
    // Update a question in a quiz
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
    
    // Function to delete a group from groups
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
    
    // Function to add a new group
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
    
    // Function to update a group's name
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
    
    
    func fetchGroupMembers(group: FriendGroup, completion: @escaping (Result<[String: String], Error>) -> Void) {
        let members = group.members
        print(members)
        getUsernames(with: members) { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let membersWitchUsernames):
                print(membersWitchUsernames)
                completion(.success(membersWitchUsernames))
            }
        }
    }
    
    // Function to add new members to a group
    func addNewMembersToGroup(group: FriendGroup, newMembers: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserID = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        guard let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == group.id }) else {
            completion(.failure(MyError.failedToUpdateGroupMembers))
            return
        }
        
        let updatedMembers = (self.friendGroups?[groupIndex].members ?? []) + newMembers
        let data = [FirestoreFields.Group.members: updatedMembers]
        
        firebaseService.setDataWithMerge(in: FirestoreFields.groupsCollection, documentId: group.id, data: data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.friendGroups?[groupIndex].members = updatedMembers
                completion(.success(()))
            }
        }
    }
    
    // Function to remove a member from a group
    func removeMemberFromGroup(group: FriendGroup, memberId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        guard let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == group.id }) else {
            completion(.failure(MyError.failedToRemoveMembersFromGroup))
            return
        }

        let updatedMembers = self.friendGroups?[groupIndex].members.filter { $0 != memberId }

        let data = [FirestoreFields.Group.members: updatedMembers ?? []]
        
        firebaseService.setDataWithMerge(in: FirestoreFields.groupsCollection, documentId: group.id, data: data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.friendGroups?[groupIndex].members = updatedMembers ?? []
                completion(.success(()))
            }
        }
    }
    
    // Function to generate a unique code
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
                    completion(uniqueCode, nil)
                } else {
                    self.generateUniqueCode(completion: completion)
                }
            }
        }
    }
    
}

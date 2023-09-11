//
//  firebaseUser.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore


// handle action and information concerning user
class FirebaseUser {
    
    static let shared = FirebaseUser(firebaseService: FirebaseService())
    
    var currentUserId: String? { return firebaseService.currentUserID }
    
    var firebaseService: FirebaseServiceProtocol
    init(firebaseService: FirebaseServiceProtocol) {
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
    
    // Function to reset password
    func resetPassword(for email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        firebaseService.resetPassword(for: email) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success():
                completion(.success(()))
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
    
    func createUser(email: String, password: String, pseudo: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let conditions: [FirestoreCondition] = [.isEqualTo(FirestoreFields.User.username, pseudo)]
        firebaseService.getDocuments(in: FirestoreFields.usersCollection, whereFields: conditions) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                print("echec 1")
            case .success(let querySnapshot):
                guard querySnapshot.isEmpty else {
                    completion(.failure(FirebaseUserError.usernameAlreadyUsed))
                    return
                }
                
                self.firebaseService.createUser(withEmail: email, password: password) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                        print("echec 2")
                    case .success(let uid):
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        
                        let inscriptionDate = Timestamp(date: Date())
                        
                        let userData: [String: Any] = [
                            FirestoreFields.id: uid,
                            FirestoreFields.User.username: pseudo,
                            FirestoreFields.User.email: email,
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
                                completion(.failure(error))
                            } else {
                                completion(.success(()))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getUserInfo(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseUserError.noUserConnected))
            return
        }
        
        firebaseService.getDocument(in: FirestoreFields.usersCollection, documentId: currentUserId) { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let data):
                guard !data.isEmpty else {
                    completion(.failure(FirebaseUserError.userInfoNotFound))
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
    }
    
    // Function to get user's quizzes
    func getUserQuizzes(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseUserError.noUserConnected))
            return
        }
        
        let conditions: [FirestoreCondition] = [.isEqualTo(FirestoreFields.creator, currentUserId)]
        firebaseService.getDocuments(in: FirestoreFields.quizzesCollection, whereFields: conditions) { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let quizzesData):
                
                guard !quizzesData.isEmpty else {
                    completion(.success(()))
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: quizzesData, options: [])
                    let decoder = JSONDecoder()
                    let quizzes = try decoder.decode([Quiz].self, from: jsonData)
                    self.userQuizzes = quizzes
                    completion(.success(()))
                                    } catch {
                                        completion(.failure(error))
                                    }
                
            }
        }
    }
    
   
    
    // Function to get user's groups
    func getUserGroups(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseUserError.noUserConnected))
            return
        }
        
        let conditions: [FirestoreCondition] = [.isEqualTo(FirestoreFields.creator, currentUserId)]
        firebaseService.getDocuments(in: FirestoreFields.groupsCollection, whereFields: conditions) { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let groupsData):
                
                guard !groupsData.isEmpty else {
                    completion(.success(()))
                    return
                }
                
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
            completion(.failure(FirebaseUserError.noUserConnected))
            return
        }
        
        let imageFileName = "\(currentUserId).jpg"
        firebaseService.storeData(in: "profile_images", fileName: imageFileName, data: imageData) { result in
            switch result {
            case .success(let downloadURL):
                completion(.success(downloadURL))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // Function to save Firestore Storage URL of the profile image in Firestore user's document
    func saveProfileImage(url: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseUserError.noUserConnected))
            return
        }
        
        firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: [FirestoreFields.User.profilePicture: url]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // Function to get Firestore storage Image from URL
    func downloadProfileImageFromURL(url: String, completion: @escaping (Data?) -> Void) {
        firebaseService.downloadData(from: url) { result in
            switch result {
            case .success(let data):
                completion(data)
            case .failure(_):
                completion(nil)
            }
        }
    }
    
    // Function to save user's new username
//    func updateUsername(username: String, completion: @escaping (Result<Void, Error>) -> Void){
//        guard let currentUserId = firebaseService.currentUserID else {
//            completion(.failure(FirebaseUserError.noUserConnected))
//            return
//        }
//
//        self.firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: [FirestoreFields.User.username: username]) { error in
//            if let error = error {
//                completion(.failure(error))
//            }
//            completion(.success(()))
//        }
//    }
//
    //-----------------------------------------------------------------------------------
    //                                 FRIENDS
    //-----------------------------------------------------------------------------------
    
    // Function to display freinds for UID's
    func fetchFriends(completion: @escaping ([String: String]?, Error?) -> Void) {
        guard let frinedUIDs = self.userInfo?.friends, !frinedUIDs.isEmpty else {
            completion([:], FirebaseUserError.noFriendsInFriendList)
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
        guard let invites = self.userInfo?.invites, !invites.isEmpty else {
            completion([:], FirebaseUserError.noInvitesInInvitesList)
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
        var usernames = [String: String]()
        var lastError: Error?
        let dispatchGroup = DispatchGroup()

        for uid in uids {
            dispatchGroup.enter()
            firebaseService.getDocument(in: FirestoreFields.usersCollection, documentId: uid) { result in
                switch result {
                case .failure(let error):
                    lastError = error
                case .success(let documentData):
                    if let username = documentData["username"] as? String {
                        usernames[uid] = username
                    } else {
                        completion(.failure(FirebaseUserError.userNotFound))
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            if let error = lastError {
                completion(.failure(error))
            } else if usernames.isEmpty {
                completion(.failure(FirebaseUserError.failedToGetData))
            } else {
                completion(.success(usernames))
            }
        }
    }
    
    // Function to send Friend request
    func sendFriendRequest(username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseUserError.noUserConnected))
            return
        }
        
        let conditions: [FirestoreCondition] = [.isEqualTo(FirestoreFields.User.username, username)]
        firebaseService.getDocuments(in: FirestoreFields.usersCollection, whereFields: conditions) { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let documentsData):
                guard let friendDocumentData = documentsData.first, let friendID = friendDocumentData["id"] as? String else {
                    completion(.failure(FirebaseUserError.userNotFound))
                    return
                }
                
                if friendID == currentUserId {
                    completion(.failure(FirebaseUserError.cantAddYourself))
                    return
                }
               
                let requestTimestamp = Timestamp(date: Date())
                // Create friend request data
                let friendRequestData: [String: Any] = [
                    FirestoreFields.User.friendRequests: [
                        friendID: [
                            FirestoreFields.status: "sent",
                            FirestoreFields.date: requestTimestamp
                        ] as [String : Any]
                    ]
                ]
                
                
                // Send friend request
                self.firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: friendRequestData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        // Create new FriendRequest
                        let newFriendRequest = aUser.FriendRequest(status: "sent", date: requestTimestamp.dateValue())
                        
                        // Add new FriendRequest to current userInfo
                        FirebaseUser.shared.userInfo?.friendRequests[friendID] = newFriendRequest
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    
    // Function to display friend requests
    func fetchFriendRequests(status: Status, completion: @escaping ([String: String]?, Error?) -> Void){
        guard let friendRequests = self.userInfo?.friendRequests, !friendRequests.isEmpty else {
            completion([:], FirebaseUserError.noFriendRequestYet)
            return
        }
        
        
        
        var players = [String: String]()
        
        let receivedRequests = friendRequests.filter { $0.value.status == status.rawValue }
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
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(FirebaseUserError.noUserConnected)); return }
        
        let data: [String: Any] = [
            "\(FirestoreFields.User.friends)": FieldValue.arrayUnion([friendID]),
            "\(FirestoreFields.User.friendRequests).\(friendID)": FieldValue.delete()
        ]

        
        firebaseService.setDataWithMerge(in: FirestoreFields.usersCollection, documentId: currentUserId, data: data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Remove friend request and add friend ID to friends
                FirebaseUser.shared.userInfo?.friendRequests.removeValue(forKey: friendID)
                FirebaseUser.shared.userInfo?.friends.append(friendID)
                completion(.success(()))
            }
        }
    }
    
    // Function to reject friend request  and delete friend request
    func rejectFriendRequest(friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(FirebaseUserError.noUserConnected)); return }
        
        let data: [String: Any] = [
            "\(FirestoreFields.User.friendRequests).\(friendID)": FieldValue.delete()
        ]
        
        firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Remove friend request
                FirebaseUser.shared.userInfo?.friendRequests.removeValue(forKey: friendID)
                completion(.success(()))
            }
        }
    }
    
   
    
    // Function to remove a friend from friends list
    func removeFriend(friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(FirebaseUserError.noUserConnected)); return }
        
        let data: [String: Any] = [
            "\(FirestoreFields.User.friends)": FieldValue.arrayRemove([friendID])
        ]
        
        firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                
                // Remove friend from friend list
                if let index = FirebaseUser.shared.userInfo?.friends.firstIndex(of: friendID) {
                    FirebaseUser.shared.userInfo?.friends.remove(at: index)
                }
                completion(.success(()))
            }
        }
    }
    
    
    //-----------------------------------------------------------------------------------
    //                                 QUIZZES
    //-----------------------------------------------------------------------------------
    
    // Function to add/create a new quizz
    func addQuiz(name: String, category_id: String, difficulty: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(FirebaseUserError.noUserConnected)); return }
        
        let quizID = UUID().uuidString
        
        generateUniqueCode { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let code):
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
        guard (firebaseService.currentUserID) != nil else { completion(.failure(FirebaseUserError.noUserConnected)); return }
        
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
            completion(.failure(FirebaseUserError.noUserConnected));
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
        guard firebaseService.currentUserID != nil else { completion(.failure(FirebaseUserError.noUserConnected)); return }
        
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
            completion(.failure(FirebaseUserError.noUserConnected));
            return
        }
        guard quiz.questions.keys.contains(questionId) else {
            completion(.failure(FirebaseUserError.questionNotFound))
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
            completion(.failure(FirebaseUserError.noUserConnected));
            return
        }
        
        guard let oldQuestion = quiz.questions[oldQuestionId] else {
            completion(.failure(FirebaseUserError.questionNotFound))
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
        guard (firebaseService.currentUserID) != nil else {  completion(.failure(FirebaseUserError.noUserConnected)); return}
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
        guard let currentUserId = firebaseService.currentUserID else {  completion(.failure(FirebaseUserError.noUserConnected)); return}
        
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
        guard firebaseService.currentUserID != nil else {completion(.failure(FirebaseUserError.noUserConnected)); return}
        let data = [FirestoreFields.Group.name: newName]
        firebaseService.updateDocument(in: FirestoreFields.groupsCollection, documentId: groupID, data: data) { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == groupID }) {
                    self.friendGroups?[groupIndex].name = newName
                    completion(.success(()))
                } else {
                    completion(.failure(FirebaseUserError.failedToUpdateGroupName))
                }
            }
        }
    }
    
    
    func fetchGroupMembers(group: FriendGroup, completion: @escaping (Result<[String: String], Error>) -> Void) {
        let members = group.members
        
        getUsernames(with: members) { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let membersWitchUsernames):
                
                completion(.success(membersWitchUsernames))
            }
        }
    }
    
    // Function to add new members to a group
    func addNewMembersToGroup(group: FriendGroup, newMembers: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard (firebaseService.currentUserID) != nil else {
            completion(.failure(FirebaseUserError.noUserConnected))
            return
        }
        
        guard let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == group.id }) else {
            completion(.failure(FirebaseUserError.failedToUpdateGroupMembers))
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
            completion(.failure(FirebaseUserError.noUserConnected))
            return
        }
        
        guard let groupIndex = self.friendGroups?.firstIndex(where: { $0.id == group.id }) else {
            completion(.failure(FirebaseUserError.failedToRemoveMembersFromGroup))
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
    func generateUniqueCode(completion: @escaping (Result<String, Error>) -> Void) {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let codeLength = 6
        let uniqueCode = String((0..<codeLength).map { _ in characters.randomElement()! })
        
        let conditions: [FirestoreCondition] = [.isEqualTo(FirestoreFields.Quiz.code, uniqueCode)]
        firebaseService.getDocuments(in: FirestoreFields.quizzesCollection, whereFields: conditions) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let quizzesData):
                if quizzesData.isEmpty {
                    completion(.success(uniqueCode))
                } else {
                    self.generateUniqueCode(completion: completion)
                }
            }
        }
    }
    
}


// Enum to handle errors
enum FirebaseUserError: Error, Equatable {
    case usernameAlreadyUsed
    case noUserConnected
    case failedToUpdateGroupMembers
    case failedToRemoveMembersFromGroup
    case failedToUpdateGroupName
    case questionNotFound
    case failedToGetData
    case userNotFound
    case noFriendsInFriendList
    case noFriendRequestYet
    case cantAddYourself
    case noInvitesInInvitesList
    case userInfoNotFound
}

//
//  FirebaseUserTests.swift
//  QuizTests
//
//  Created by Guillaume Bourlart on 22/05/2023.
//
@testable import Quiz
import XCTest

final class FirebaseUserTests: XCTestCase {
    
    var firebaseUser: FirebaseUser!
    
    var firebaseService: FirebaseServiceStub!
    var networkRequestStub: NetworkRequestStub!
    var service: Service!
    
    override func setUp() {
        super.setUp()
        firebaseService = FirebaseServiceStub()
        firebaseUser = FirebaseUser(firebaseService: firebaseService)
    }
    
    override func tearDown() {
        firebaseUser = nil
        firebaseService = nil
        super.tearDown()
    }
    
    //-----------------------------------------------------------------------------------
    //                                 CONNEXION ET INSCRIPTION
    //-----------------------------------------------------------------------------------
    
    func testSignInUser_success() {
        // Arrange
        let email = "test@example.com"
        let password = "password"
        
        firebaseService.stubbedDocumentError = nil
        let expectation = XCTestExpectation(description: "Sign in user success")
        firebaseService.stubbedDocumentSnapshot = fakeResponsesData.mockUserData
        
        
        // Act
        firebaseUser.signInUser(email: email, password: password) { result in
            // Assert
            switch result {
            case .success:
                expectation.fulfill()
            case .failure:
                XCTFail("Expected sign in to succeed")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCreateUser_success() {
        // 1. Arrange
        let email = "test@example.com"
        let password = "password"
        let pseudo = "TestUser"
        let firstName = "Test"
        let lastName = "User"
        let birthDate = Date()
        
        
        firebaseService.stubbedQuerySnapshotData = [] // username not used
        
        let expectation = XCTestExpectation(description: "Create user success")
        
        // 2. Act
        firebaseUser.createUser(email: email, password: password, pseudo: pseudo, firstName: firstName, lastName: lastName, birthDate: birthDate) { uid, error in
            // 3. Assert
            if let uid = uid, error == nil {
                XCTAssertEqual(uid, self.firebaseService.currentUserID)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    //-----------------------------------------------------------------------------------
    //                                GET INFO, QUIZZES AND GROUPS
    //-----------------------------------------------------------------------------------
    
    func testGetUserInfo_success() {
        // Given
        let expectedUser = aUser(id: "id", username: "", email: "", first_name: "", last_name: "", birth_date: Date(), inscription_date: Date(), rank: 3, points: 3, profile_picture: "", friends: [""], friendRequests: [:])
        firebaseUser.userInfo = expectedUser // Should include expectedUser data
        firebaseService.stubbedDocumentSnapshot = fakeResponsesData.mockUserData
        firebaseService.stubbedDocumentError = nil
        let expectation = XCTestExpectation(description: "Get user info success")
        
        // When
        firebaseUser.getUserInfo() { result in
            // Then
            switch result {
            case .success():
                expectation.fulfill()
            case .failure(let error):
                print("Error: \(error)") // Print error for debugging
                XCTFail("Expected success but got failure")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGetUserQuizzes_success() {
        // Arrange
        let expectedQuizzes = [Quiz(id: "id", name: "", category_id: "", creator: "", difficulty: "", questions: [UniversalQuestion(id: "questionId", category: "category", type: "type", difficulty: "medium", question: "Question?", correct_answer: "Answer", incorrect_answers: ["Wrong"], explanation: "Explanation")], average_score: 0, users_completed: 0, code: "")]
        firebaseUser.userQuizzes? = expectedQuizzes
        
        let expectation = XCTestExpectation(description: "Get user quizzes success")
        
        // Act
        firebaseUser.getUserQuizzes { result in
            // Assert
            switch result {
            case .success:
                XCTAssertEqual(self.firebaseUser.userQuizzes![0].id, "id")
                expectation.fulfill()
            case .failure:
                XCTFail("getUserQuizzes failed")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetUserQuizzes_failure() {
        // Arrange
        firebaseService.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get document"])
        
        let expectation = XCTestExpectation(description: "Get user quizzes failure")
        
        // Act
        firebaseUser.getUserQuizzes { result in
            // Assert
            switch result {
            case .success:
                XCTFail("getUserQuizzes should not succeed")
            case .failure(let error):
                XCTAssertEqual(error.localizedDescription, "Failed to get document")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    //-----------------------------------------------------------------------------------
    //                                FRIENDS
    //-----------------------------------------------------------------------------------
    
    func testFetchFriends() {
        // Préparer les mock et stub
        let expectedUser = aUser(id: "id", username: "", email: "", first_name: "", last_name: "", birth_date: Date(), inscription_date: Date(), rank: 3, points: 3, profile_picture: "", friends: ["friendId"], friendRequests: [:])
        firebaseUser.userInfo = expectedUser
        
        // Test
        let fetchedFriends = firebaseUser.fetchFriends()
        
        // Assert
        XCTAssertEqual(fetchedFriends, ["friendId"])
    }
    
    func testSendFriendRequest() {
        // Préparer les mock et stub
        let request = ["id": aUser.FriendRequest(status: "sent", date: Date())]
        let expectedUser = aUser(id: "id", username: "", email: "", first_name: "", last_name: "", birth_date: Date(), inscription_date: Date(), rank: 3, points: 3, profile_picture: "", friends: ["friendId"], friendRequests: [:])
        firebaseService.stubbedQuerySnapshotData = fakeResponsesData.mockUsersData
        firebaseUser.userInfo = expectedUser
        
        let expectation = XCTestExpectation(description: "Get user quizzes failure")
        
        
        // Test
        firebaseUser.sendFriendRequest(username: "username") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("La méthode a échoué avec l'erreur : \(error)")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchFriendRequests() {
        // Préparer les mock et stub
        let request = ["friendId2": aUser.FriendRequest(status: "received", date: Date())]
        let expectedUser = aUser(id: "id", username: "", email: "", first_name: "", last_name: "", birth_date: Date(),inscription_date: Date(), rank: 3, points: 3, profile_picture: "", friends: ["friendId"], friendRequests: request)
        firebaseUser.userInfo = expectedUser
        
        
        // Test
        let fetchedFriendRequests = firebaseUser.fetchFriendRequests()
        
        // Assert
        XCTAssertEqual(fetchedFriendRequests, ["friendId2"])
    }
    
    func testAcceptFriendRequest() {
        // Préparer les mock et stub
        let request = ["friendId": aUser.FriendRequest(status: "received", date: Date())]
        let expectedUser = aUser(id: "id", username: "", email: "", first_name: "", last_name: "", birth_date: Date(), inscription_date: Date(), rank: 3, points: 3, profile_picture: "", friends: [], friendRequests: request)
        firebaseUser.userInfo = expectedUser
        
        let expectation = XCTestExpectation(description: "Get user quizzes failure")
        
        
        // Test
        firebaseUser.acceptFriendRequest(friendID: "friendId") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("La méthode a échoué avec l'erreur : \(error)")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRejectFriendRequest() {
        // Préparer les mock et stub
        let request = ["friendId": aUser.FriendRequest(status: "received", date: Date())]
        let expectedUser = aUser(id: "id", username: "", email: "", first_name: "", last_name: "", birth_date: Date(), inscription_date: Date(), rank: 3, points: 3, profile_picture: "", friends: [], friendRequests: request)
        firebaseUser.userInfo = expectedUser
        
        let expectation = XCTestExpectation(description: "Get user quizzes failure")
        
        
        // Test
        firebaseUser.rejectFriendRequest(friendID: "friendId") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("La méthode a échoué avec l'erreur : \(error)")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRemoveFriend() {
        // Préparer les mock et stub
        let expectedUser = aUser(id: "id", username: "", email: "", first_name: "", last_name: "", birth_date: Date(), inscription_date: Date(), rank: 3, points: 3, profile_picture: "", friends: ["friendId"], friendRequests: [:])
        firebaseUser.userInfo = expectedUser
        
        let expectation = XCTestExpectation(description: "Get user info success")
        
        // Test
        firebaseUser.removeFriend(friendID: "friendId") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                XCTAssertEqual(self.firebaseUser.userInfo?.friends, [])
                expectation.fulfill()
            case .failure(let error):
                XCTFail("La méthode a échoué avec l'erreur : \(error)")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    //-----------------------------------------------------------------------------------
    //                                QUIZZES
    //-----------------------------------------------------------------------------------
    
    
    func testAddQuiz() {
        // Prepare mock and stub
        let expectedUser = aUser(id: "id", username: "", email: "", first_name: "", last_name: "", birth_date: Date(), inscription_date: Date(), rank: 3, points: 3, profile_picture: "", friends: [], friendRequests: [:])
        firebaseUser.userInfo = expectedUser
        
        firebaseUser.userQuizzes = []
        let expectation = XCTestExpectation(description: "Get user info success")
        
        // Test
        firebaseUser.addQuiz(name: "testQuiz", category_id: "categoryId", difficulty: "medium") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                XCTAssertEqual(self.firebaseUser.userQuizzes!.count, 1)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Method failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteQuiz() {
        // Prepare mock and stub
        let expectedUser = aUser(id: "id", username: "", email: "", first_name: "", last_name: "", birth_date: Date(), inscription_date: Date(), rank: 3, points: 3, profile_picture: "", friends: [], friendRequests: [:])
        firebaseUser.userInfo = expectedUser
        let quiz = Quiz(id: "", name: "", category_id: "", creator: "", difficulty: "", questions: [], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
       
        let expectation = XCTestExpectation(description: "Get user info success")
        
        
        
        // Test
        firebaseUser.deleteQuiz(quiz: firebaseUser.userQuizzes![0]) { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                XCTAssertEqual(self.firebaseUser.userQuizzes?.count, 0)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Method failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddQuestionToQuiz() {
        // Prepare mock and stub
        let quiz = Quiz(id: "", name: "", category_id: "", creator: "", difficulty: "", questions: [], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        
        let expectation = XCTestExpectation(description: "Get user info success")
        
        
    
        // Test
        firebaseUser.addQuestionToQuiz(quiz: firebaseUser.userQuizzes![0], question: "Question?", correctAnswer: "Answer", incorrectAnswers: ["Wrong", "", ""], explanation: "Explanation") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                XCTAssertEqual(self.firebaseUser.userQuizzes![0].questions.count, 1)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Method failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateQuiz() {
        // Prepare mock and stub
        let quiz = Quiz(id: "id",name: "", category_id: "", creator: "", difficulty: "", questions: [], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        
        let expectation = XCTestExpectation(description: "Get user info success")
        
        
        
        // Test
        firebaseUser.updateQuiz(quizID: "id", newName: "NewName", newCategoryID: "NewCategory", newDifficulty: "easy") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                XCTAssertEqual(self.firebaseUser.userQuizzes?[0].name, "NewName")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Method failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteQuestionFromQuiz() {
        // Prepare mock and stub
        let quiz = Quiz(id: "",name: "", category_id: "", creator: "", difficulty: "", questions: [], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        let questions = [UniversalQuestion(id: "id", category: "", type: "", difficulty: "", question: "", correct_answer: "", incorrect_answers: [], explanation: "")]
        firebaseUser.userQuizzes![0].questions = questions
        
        let expectation = XCTestExpectation(description: "Get user info success")
        
        
        
        // Test
        firebaseUser.deleteQuestionFromQuiz(quiz: firebaseUser.userQuizzes![0], questionText: "") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                XCTAssertEqual(self.firebaseUser.userQuizzes?[0].questions.count, 0)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Method failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateQuestionInQuiz() {
        // Prepare mock and stub
        let quiz = Quiz(id: "", name: "", category_id: "", creator: "", difficulty: "", questions: [], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        let questions = [UniversalQuestion(id: "id", category: "", type: "", difficulty: "", question: "", correct_answer: "", incorrect_answers: [], explanation: "")]
        firebaseUser.userQuizzes![0].questions = questions
        
        let expectation = XCTestExpectation(description: "Get user info success")
        
        
        
        // Test
        firebaseUser.updateQuestionInQuiz(quiz: firebaseUser.userQuizzes![0], oldQuestion: questions[0], newQuestionText: "NewQuestion?", correctAnswer: "NewAnswer", incorrectAnswers: ["NewWrong"], explanation: "NewExplanation") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                XCTAssertEqual(self.firebaseUser.userQuizzes![0].questions[0].question, "NewQuestion?")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Method failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    //-----------------------------------------------------------------------------------
    //                                GROUPS
    //-----------------------------------------------------------------------------------
    
    // MARK: - Tests for deleteGroup
    func testDeleteGroupSuccess() {
        let group = FriendGroup(id: "group1", creator: "", name: "group 1", members: [])
        firebaseService.stubbedDocumentError = nil
        
        let expectation = self.expectation(description: "Delete group")
        firebaseUser.deleteGroup(group: group) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Delete group failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteGroupFailure() {
        let group = FriendGroup(id: "group1", creator: "", name: "group 1", members: [])
        firebaseService.stubbedDocumentError = MyError.generalError
        
        let expectation = self.expectation(description: "Delete group failure")
        firebaseUser.deleteGroup(group: group) { result in
            switch result {
            case .success:
                XCTFail("Delete group should have failed")
            case .failure:
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Tests for addGroup
    func testAddGroupSuccess() {
        firebaseService.stubbedDocumentError = nil
        
        let expectation = self.expectation(description: "Add group")
        firebaseUser.addGroup(name: "group 1") { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Add group failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAddGroupFailure() {
        firebaseService.stubbedDocumentError = MyError.generalError
        
        let expectation = self.expectation(description: "Add group failure")
        firebaseUser.addGroup(name: "group 1") { result in
            switch result {
            case .success:
                XCTFail("Add group should have failed")
            case .failure:
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARL: - Tests for updateGroupName
    func testUpdateGroupNameSuccess() {
        firebaseService.stubbedDocumentError = nil
        let friednGroup = FriendGroup(id: "groupId", creator: "", name: "", members: [])
        firebaseUser.friendGroups = [friednGroup]
        
        let expectation = self.expectation(description: "Update group name")
        firebaseUser.updateGroupName(groupID: "groupId", newName: "new group 1") { result in
            switch result {
            case .success:
                XCTAssertEqual(self.firebaseUser.friendGroups![0].name, "new group 1")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Update group name failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateGroupNameFailure() {
        firebaseService.stubbedDocumentError = MyError.generalError
        
        let expectation = self.expectation(description: "Update group name failure")
        firebaseUser.updateGroupName(groupID: "group1", newName: "new group 1") { result in
            switch result {
            case .success:
                XCTFail("Update group name should have failed")
            case .failure:
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Tests for addNewMembersToGroup
    func testAddNewMembersToGroupSuccess() {
        firebaseUser.friendGroups = [FriendGroup(id: "group1", creator: "", name: "group 1", members: [])]
        firebaseService.stubbedDocumentError = nil
        
        
        let expectation = self.expectation(description: "Add new members to group")
        firebaseUser.addNewMembersToGroup(group: firebaseUser.friendGroups![0], newMembers: ["member1"]) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Add new members to group failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAddNewMembersToGroupFailure() {
        let group = FriendGroup(id: "group1", creator: "", name: "group 1", members: [])
        firebaseService.stubbedDocumentError = MyError.generalError
        
        let expectation = self.expectation(description: "Add new members to group failure")
        firebaseUser.addNewMembersToGroup(group: group, newMembers: ["member1"]) { result in
            switch result {
            case .success:
                XCTFail("Add new members to group should have failed")
            case .failure:
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Tests for removeMemberFromGroup
    func testRemoveMemberFromGroupSuccess() {
        firebaseService.stubbedDocumentError = nil
        let friednGroup = FriendGroup(id: "groupId", creator: "", name: "", members: ["member1"])
        firebaseUser.friendGroups = [friednGroup]
        
        let expectation = self.expectation(description: "Remove member from group")
        firebaseUser.removeMemberFromGroup(group: firebaseUser.friendGroups![0], memberId: "member1") { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Remove member from group failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testRemoveMemberFromGroupFailure() {
        let group = FriendGroup(id: "group1", creator: "", name: "group 1", members: ["member1"])
        firebaseService.stubbedDocumentError = MyError.generalError
        
        let expectation = self.expectation(description: "Remove member from group failure")
        firebaseUser.removeMemberFromGroup(group: group, memberId: "member1") { result in
            switch result {
            case .success:
                XCTFail("Remove member from group should have failed")
            case .failure:
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Tests for generateUniqueCode
    func testGenerateUniqueCodeSuccess() {
        firebaseService.stubbedQuerySnapshotData = []
        
        let expectation = self.expectation(description: "Generate unique code")
        firebaseUser.generateUniqueCode() { code,error  in
            if let error = error {
                print(error)
            }else if let code = code {
                XCTAssertNotNil(code, "Code should not be nil")
                XCTAssertFalse(code.isEmpty, "Code should not be empty")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

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
    
    var firebaseServiceStub: FirebaseServiceStub!
    
    
    override func setUp() {
        super.setUp()
        firebaseServiceStub = FirebaseServiceStub()
        firebaseUser = FirebaseUser(firebaseService: firebaseServiceStub)
        
        
        firebaseUser.userInfo = CurrentUser(id: "id", username: "", email: "", inscription_date: Date(), rank: 3, points: 3, invites: ["userID":"initeID"], profile_picture: "", friends: ["friendUID1", "friendUID2"], friendRequests: ["user2": CurrentUser.FriendRequest(status: "sent", date: Date())])
        firebaseUser.userQuizzes = [Quiz(id: "quiz1", name: "quiz1", category_id: "2", creator: "user1", difficulty: "", questions: ["": UniversalQuestion(category: "", type: "", difficulty: "", question: "", correct_answer: "", incorrect_answers: ["", "", ""], explanation: "")], average_score: 3, users_completed: 3, code: "dedcx")]
        firebaseUser.friendGroups = [FriendGroup(id: "group1", creator: "user1", name: "group1", members: ["user2", "user3"])]
        
    }
    
    override func tearDown() {
        firebaseUser = nil
        firebaseServiceStub.stubbedDocumentError = nil
        firebaseServiceStub.stubbedDocumentSnapshots = nil
        firebaseServiceStub.stubbedQuerySnapshotDatas = nil
        firebaseServiceStub.stubbedListenerData = nil
        firebaseServiceStub = nil
        super.tearDown()
    }
    //    
    //    //-----------------------------------------------------------------------------------
    //    //                                 CONNEXION ET INSCRIPTION
    //    //-----------------------------------------------------------------------------------
    
    func testSignOut_withStubbedError_returnsError() {
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseServiceStub.stubbedDocumentError = expectedError
        let expectation = self.expectation(description: "signout failed")
        
        // Act
        var returnedError: Error?
        firebaseUser.signOut() { result in
            switch result {
            case .failure(let error):
                returnedError = error
            case .success:
                break
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        // Assert
        XCTAssertEqual(expectedError, returnedError as NSError?)
    }
    
    func testSignOut_withoutStubbedError_returnsSuccess() {
        // Arrange
        let expectation = self.expectation(description: "signout succeed")
        // Act
        var returnedError: Error?
        firebaseUser.signOut() { result in
            switch result {
            case .failure(let error):
                returnedError = error
            case .success:
                break
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        // Assert
        XCTAssertNil(returnedError as NSError?)
    }
    
    func testResetPassword_withStubbedError_returnsError() {
        let expectation = self.expectation(description: "")
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseServiceStub.stubbedDocumentError = expectedError
        
        // Act
        var returnedError: Error?
        firebaseUser.resetPassword(for: "test@test.com") { result in
            switch result {
            case .failure(let error):
                returnedError = error
            case .success:
                break
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        // Assert
        XCTAssertEqual(expectedError, returnedError as NSError?)
    }
    
    func testResetPassword_withoutStubbedError_returnsSuccess() {
        // Arrange
        firebaseServiceStub.stubbedDocumentError = nil
        let expectation = self.expectation(description: "")
        
        // Act
        var isSuccess = false
        firebaseUser.resetPassword(for: "test@test.com") { result in
            switch result {
            case .failure:
                break
            case .success:
                isSuccess = true
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertTrue(isSuccess)
    }
    
    func testSignInUser_withStubbedError_returnsError() {
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseServiceStub.stubbedDocumentError = expectedError
        let expectation = self.expectation(description: "")
        
        // Act
        var returnedError: Error?
        firebaseUser.signInUser(email: "test@test.com", password: "password") { result in
            switch result {
            case .failure(let error):
                returnedError = error
            case .success:
                break
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertEqual(expectedError, returnedError as NSError?)
    }
    
    func testSignInUser_withoutStubbedError_returnsSuccess() {
        // Arrange
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData]
        
        // Act
        var isSuccess = false
        let expectation = self.expectation(description: "signInUser finishes")
        
        firebaseUser.signInUser(email: "test@test.com", password: "password") { result in
            switch result {
            case .failure:
                break
            case .success:
                isSuccess = true
            }
            expectation.fulfill()  // Mark the expectation as having been fulfilled
        }
        
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertTrue(isSuccess)
    }
    
    func testCreateUser_withStubbedError_returnsError() {
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        let expectation = self.expectation(description: "")
        firebaseServiceStub.stubbedDocumentError = expectedError
        
        // Act
        var returnedError: Error?
        firebaseUser.createUser(email: "test@test.com", password: "password", pseudo: "") { result in
            switch result {
            case .failure(let error):
                returnedError = error
            case .success:
                break
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertEqual(expectedError, returnedError as NSError?)
    }
    
    func testCreateUser_withoutStubbedError_returnsUserId() {
        firebaseServiceStub.stubbedQuerySnapshotDatas = []
        
        // Act
        let expectation = self.expectation(description: "")
        var nserror: Error?
        firebaseUser.createUser(email: "test@test.com", password: "password", pseudo: "") { result in
            
            switch result {
            case .failure(let error):
                nserror = error
            case .success():
                break
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertNil(nserror)
    }
    
    //-----------------------------------------------------------------------------------
    //                                GET INFO, QUIZZES AND GROUPS
    //-----------------------------------------------------------------------------------
    
    func testGetUserInfo_withStubbedError_returnsError() {
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseServiceStub.stubbedDocumentError = expectedError
        let expectation = self.expectation(description: "")
        // Act
        var returnedError: Error?
        firebaseUser.getUserInfo() { result in
            switch result {
            case .failure(let error):
                returnedError = error
            case .success:
                break
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertEqual(expectedError, returnedError as NSError?)
    }
    
    func testGetUserInfo_withoutStubbedError_returnsSuccess() {
        // Arrange
        firebaseServiceStub.stubbedDocumentError = nil
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData]
        let expectation = self.expectation(description: "")
        // Act
        var isSuccess = false
        firebaseUser.getUserInfo() { result in
            switch result {
            case .failure:
                break
            case .success:
                isSuccess = true
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertTrue(isSuccess)
    }
    
    func testGetUserQuizzes_withStubbedError_returnsError() {
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseServiceStub.stubbedDocumentError = expectedError
        let expectation = self.expectation(description: "")
        // Act
        var returnedError: Error?
        firebaseUser.getUserQuizzes() { result in
            switch result {
            case .failure(let error):
                returnedError = error
            case .success:
                break
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertEqual(expectedError, returnedError as NSError?)
    }
    
    func testGetUserQuizzes_withoutStubbedError_returnsSuccess() {
        // Arrange
        firebaseServiceStub.stubbedQuerySnapshotDatas = [fakeResponsesData.mockQuizzesData]
        let expectation = self.expectation(description: "")
        // Act
        firebaseUser.getUserQuizzes() { result in
            switch result {
            case .failure:
                XCTFail("expected to success")
            case .success:
                expectation.fulfill()
            }
            
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testGetUserGroups_withStubbedError_returnsError() {
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseServiceStub.stubbedDocumentError = expectedError
        let expectation = self.expectation(description: "")
        // Act
        var returnedError: Error?
        firebaseUser.getUserGroups() { result in
            switch result {
            case .failure(let error):
                returnedError = error
            case .success:
                break
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertEqual(expectedError, returnedError as NSError?)
    }
    
    func testGetUserGroups_withoutStubbedError_returnsSuccess() {
        // Arrange
        firebaseServiceStub.stubbedQuerySnapshotDatas = [fakeResponsesData.mockQGroupsData]
        let expectation = self.expectation(description: "")
        // Act
        var isSuccess = false
        firebaseUser.getUserGroups() { result in
            switch result {
            case .failure:
                break
            case .success:
                isSuccess = true
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertTrue(isSuccess)
    }
    
    func testSaveImageInStorage_withStubbedError_returnsError() {
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseServiceStub.stubbedDocumentError = expectedError
        let expectation = self.expectation(description: "")
        // Act
        var returnedError: Error?
        let imageData = Data() // Remplacez par une image de test réelle
        firebaseUser.saveImageInStorage(imageData: imageData) { result in
            switch result {
            case .failure(let error):
                returnedError = error
            case .success:
                break
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertEqual(expectedError, returnedError as NSError?)
    }
    
    func testSaveImageInStorage_withoutStubbedError_returnsSuccess() {
        // Arrange
        firebaseServiceStub.stubbedDocumentError = nil
        let expectation = self.expectation(description: "")
        // Act
        var isSuccess = false
        let imageData = Data() // Remplacez par une image de test réelle
        firebaseUser.saveImageInStorage(imageData: imageData) { result in
            switch result {
            case .failure:
                break
            case .success:
                isSuccess = true
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertTrue(isSuccess)
    }
    
    func testSaveProfileImage_withStubbedError_returnsError() {
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseServiceStub.stubbedDocumentError = expectedError
        let expectation = self.expectation(description: "")
        // Act
        var returnedError: Error?
        firebaseUser.saveProfileImage(url: "http://testurl.com") { result in
            switch result {
            case .failure(let error):
                returnedError = error
            case .success:
                break
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertEqual(expectedError, returnedError as NSError?)
    }
    
    func testSaveProfileImage_withoutStubbedError_returnsSuccess() {
        // Arrange
        firebaseServiceStub.stubbedDocumentError = nil
        let expectation = self.expectation(description: "")
        // Act
        var isSuccess = false
        firebaseUser.saveProfileImage(url: "http://testurl.com") { result in
            switch result {
            case .failure:
                break
            case .success:
                isSuccess = true
            }
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
        // Assert
        XCTAssertTrue(isSuccess)
    }
    
    func testDownloadProfileImageFromURL_returnsData() {
        firebaseServiceStub.stubbedDownloadData = "Test data".data(using: .utf8)
        // Act
        var returnedData: Data?
        let expectation = self.expectation(description: "")
        firebaseUser.downloadProfileImageFromURL(url: "http://testurl.com") { data in
            returnedData = data
            expectation.fulfill()
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        // Assert
        XCTAssertNotNil(returnedData)
    }
    
    
    
    
    
    //-----------------------------------------------------------------------------------
    //                                FRIENDS
    //-----------------------------------------------------------------------------------
    
    
    func testFetchInvites_withInvites_returnsInvitesDict() {
        // Arrange
        let expectation = self.expectation(description: "Fetch Invites")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData, fakeResponsesData.mockUserData]
        
        firebaseUser.fetchInvites { invites, error in
            if let error {
                XCTFail("expected to success")
            } else {
                expectation.fulfill()
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSendFriendRequest_withValidUsername_returnsSuccess() {
        // Arrange
        let expectation = self.expectation(description: "Send Friend Request")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData]
        firebaseServiceStub.stubbedQuerySnapshotDatas = [fakeResponsesData.mockUsersData]
        
        firebaseUser.sendFriendRequest(username: "user3") { result in
            switch result {
            case .failure:
                XCTFail("expected to success")
            case .success:
                expectation.fulfill()
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFetchFriendRequests_withRequests_returnsRequestsDict() {
        // Arrange
        let expectation = self.expectation(description: "Fetch Friend Requests")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData, fakeResponsesData.mockUserData]
        
        
        firebaseUser.fetchFriendRequests(status: .sent) { requests, error in
            if let error {
                XCTFail("expected to success")
            } else {
                expectation.fulfill()
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAcceptFriendRequest_withValidId_returnsSuccess() {
        // Arrange
        let expectation = self.expectation(description: "Accept Friend Request")
        
        firebaseUser.acceptFriendRequest(friendID: "validFriendId", friendUsername: "validUsername") { result in
            switch result {
            case .failure:
                XCTFail("expected to success")
            case .success:
                expectation.fulfill()
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRejectFriendRequest_withValidId_returnsSuccess() {
        // Arrange
        let expectation = self.expectation(description: "Reject Friend Request")
        
        firebaseUser.rejectFriendRequest(friendID: "validFriendId") { result in
            switch result {
            case .failure:
                XCTFail("expected to success")
            case .success:
                expectation.fulfill()
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRemoveFriend_withValidId_returnsSuccess() {
        // Arrange
        let expectation = self.expectation(description: "Remove Friend")
        
        firebaseUser.removeFriend(friendID: "validFriendId") { result in
            switch result {
            case .failure:
                XCTFail("expected to success")
            case .success:
                expectation.fulfill()
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFetchFriends_withError_returnsError() {
        // Arrange
        let expectation = self.expectation(description: "Fetch Friends")
        firebaseServiceStub.stubbedDocumentError = FirebaseUserError.noFriendsInFriendList
        
        // Act
        firebaseUser.fetchFriends { friends, error in
            // Assert
            XCTAssertNil(friends)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFetchInvites_withError_returnsError() {
        // Arrange
        let expectation = self.expectation(description: "Fetch Invites")
        firebaseServiceStub.stubbedDocumentError = FirebaseUserError.noInvitesInInvitesList
        
        // Act
        firebaseUser.fetchInvites { invites, error in
            // Assert
            XCTAssertNil(invites)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testSendFriendRequest_withError_returnsError() {
        // Arrange
        let expectation = self.expectation(description: "Send Friend Request")
        firebaseServiceStub.stubbedDocumentError = FirebaseUserError.userNotFound
        let username = "user1"
        
        // Act
        firebaseUser.sendFriendRequest(username: username) { result in
            // Assert
            switch result {
            case .success:
                XCTFail("expected to fail")
            case .failure(_):
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFetchFriendRequests_withError_returnsError() {
        // Arrange
        let expectation = self.expectation(description: "Fetch Friend Requests")
        firebaseServiceStub.stubbedDocumentError = FirebaseUserError.noFriendRequestYet
        
        // Act
        firebaseUser.fetchFriendRequests(status: .sent) { friends, error in
            // Assert
            XCTAssertNil(friends)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testAcceptFriendRequest_withError_returnsError() {
        // Arrange
        let expectation = self.expectation(description: "Accept Friend Request")
        firebaseServiceStub.stubbedDocumentError = FirebaseUserError.noUserConnected
        let friendID = "friend1"
        let friendUsername = "friendName"
        
        // Act
        firebaseUser.acceptFriendRequest(friendID: friendID, friendUsername: friendUsername) { result in
            // Assert
            switch result {
            case .success:
                XCTFail("expected to fail")
            case .failure(_):
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRejectFriendRequest_withError_returnsError() {
        // Arrange
        let expectation = self.expectation(description: "Reject Friend Request")
        firebaseServiceStub.stubbedDocumentError = FirebaseUserError.noUserConnected
        let friendID = "friend1"
        
        // Act
        firebaseUser.rejectFriendRequest(friendID: friendID) { result in
            // Assert
            switch result {
            case .success:
                XCTFail("expected to fail")
            case .failure(_):
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRemoveFriend_withError_returnsError() {
        // Arrange
        let expectation = self.expectation(description: "Remove Friend")
        firebaseServiceStub.stubbedDocumentError = FirebaseUserError.noUserConnected
        let friendID = "friend1"
        
        // Act
        firebaseUser.removeFriend(friendID: friendID) { result in
            // Assert
            switch result {
            case .success:
                XCTFail("expected to fail")
            case .failure(_):
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    //-----------------------------------------------------------------------------------
    //                                QUIZZES
    //-----------------------------------------------------------------------------------
    
    
    func testAddQuiz() {
        // Prepare mock and stub
        
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
        let quiz = Quiz(id: "", name: "", category_id: "", creator: "", difficulty: "", questions: [:], average_score: 0, users_completed: 0, code: "")
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
        let quiz = Quiz(id: "", name: "", category_id: "", creator: "", difficulty: "", questions: [:], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        
        let expectation = XCTestExpectation(description: "Get user info success")
        
        
        
        // Test
        firebaseUser.addQuestionToQuiz(quiz: firebaseUser.userQuizzes![0], questionText: "Question?", correctAnswer: "Answer", incorrectAnswers: ["Wrong", "", ""], explanation: "Explanation") { result in
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
        let quiz = Quiz(id: "id",name: "", category_id: "", creator: "", difficulty: "", questions: [:], average_score: 0, users_completed: 0, code: "")
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
        let quiz = Quiz(id: "",name: "", category_id: "", creator: "", difficulty: "", questions: [:], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        let questions = ["questionID": UniversalQuestion(id: "id", category: "", type: "", difficulty: "", question: "", correct_answer: "", incorrect_answers: [], explanation: "")]
        firebaseUser.userQuizzes![0].questions = questions
        
        let expectation = XCTestExpectation(description: "Get user info success")
        
        
        
        // Test
        firebaseUser.deleteQuestionFromQuiz(quiz: firebaseUser.userQuizzes![0], questionId: "questionID") { result in
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
        let quiz = Quiz(id: "", name: "", category_id: "", creator: "", difficulty: "", questions: [:], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        let questions = ["id": UniversalQuestion(id: "id", category: "", type: "", difficulty: "", question: "", correct_answer: "", incorrect_answers: [], explanation: "")]
        firebaseUser.userQuizzes![0].questions = questions
        
        let expectation = XCTestExpectation(description: "Get user info success")
        
        // Test
        firebaseUser.updateQuestionInQuiz(quiz: firebaseUser.userQuizzes![0], oldQuestionId: "id", newQuestionText: "NewQuestion?", correctAnswer: "NewAnswer", incorrectAnswers: ["NewWrong"], explanation: "NewExplanation") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Method failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateQuestionInQuiz_failed() {
        // Prepare mock and stub
        let quiz = Quiz(id: "", name: "", category_id: "", creator: "", difficulty: "", questions: [:], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        let questions = ["id": UniversalQuestion(id: "id", category: "", type: "", difficulty: "", question: "", correct_answer: "", incorrect_answers: [], explanation: "")]
        firebaseUser.userQuizzes![0].questions = questions
        
        firebaseServiceStub.stubbedDocumentError = NSError()
        
        let expectation = XCTestExpectation(description: "Get user info success")
        
        // Test
        firebaseUser.updateQuestionInQuiz(quiz: firebaseUser.userQuizzes![0], oldQuestionId: "id", newQuestionText: "NewQuestion?", correctAnswer: "NewAnswer", incorrectAnswers: ["NewWrong"], explanation: "NewExplanation") { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
                XCTFail("Method succee, excpected error")
            case .failure(_):
                expectation.fulfill()
                
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    //-----------------------------------------------------------------------------------
    //                                GROUPS
    //-----------------------------------------------------------------------------------
    
    func test_fetchGroupMembers_success(){
        let group = FriendGroup(id: "group1", creator: "userID", name: "group 1", members: ["user2", "user4"])
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData, fakeResponsesData.mockUserData]
        
        let expectation = self.expectation(description: "Delete group")
        firebaseUser.fetchGroupMembers(group: group) { result in
            switch result {
            case .success(let usernames):
                XCTAssertEqual(group.members.count, usernames.count)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Delete group failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_fetchGroupMembers_failed(){
        let group = FriendGroup(id: "group1", creator: "", name: "group 1", members: ["user2", "user3", "user4"])
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData, fakeResponsesData.mockUserData, fakeResponsesData.mockUserData]
        firebaseServiceStub.stubbedDocumentError = NSError()
        
        let expectation = self.expectation(description: "Delete group")
        firebaseUser.fetchGroupMembers(group: group) { result in
            switch result {
            case .success:
                XCTFail("expected to fail")
            case .failure(_):
                expectation.fulfill()
                
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Tests for deleteGroup
    func testDeleteGroupSuccess() {
        let group = FriendGroup(id: "group1", creator: "", name: "group 1", members: [])
        
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
        firebaseServiceStub.stubbedDocumentError = NSError()
        
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
        firebaseServiceStub.stubbedDocumentError = NSError()
        
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
        firebaseServiceStub.stubbedDocumentError = NSError()
        
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
        firebaseServiceStub.stubbedDocumentError = NSError()
        
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
        firebaseServiceStub.stubbedDocumentError = NSError()
        
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
        firebaseServiceStub.stubbedDocumentSnapshots = [[:]]
        
        let expectation = self.expectation(description: "Generate unique code")
        firebaseUser.generateUniqueCode() { result  in
            switch result {
            case .failure(_):
                XCTFail("unexpected error")
            case .success(let code):
                XCTAssertNotNil(code, "Code should not be nil")
                XCTAssertFalse(code.isEmpty, "Code should not be empty")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

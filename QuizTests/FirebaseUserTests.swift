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
    
    func testGivenError_WhenSignOut_ThenReturnFailure() {
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseServiceStub.stubbedDocumentError = expectedError
        let expectation = self.expectation(description: "signout failed")
        
        firebaseUser.signOut() { result in
            switch result {
            case .failure(_):
                expectation.fulfill()
            case .success:
                XCTFail("Expected failure, got success instead")
            }
            
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testGivenNoError_WhenSignOut_ThenReturnSuccess() {
        // Arrange
        let expectation = self.expectation(description: "signout succeed")
        // Act
        firebaseUser.signOut() { result in
            switch result {
            case .failure(_):
                XCTFail("Expected success, got failure instead")
            case .success:
                
                expectation.fulfill()
            }
            
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testGivenError_WhenResetPassword_ThenReturnFailure() {
        let expectation = self.expectation(description: "")
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseServiceStub.stubbedDocumentError = expectedError
        
        // Act
        
        firebaseUser.resetPassword(for: "test@test.com") { result in
            switch result {
            case .failure(_):
                expectation.fulfill()
            case .success:
                XCTFail("Expected failure, got success instead")
            }
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testGivenNoError_WhenResetPassword_ThenReturnSuccess() {
        // Arrange
        firebaseServiceStub.stubbedDocumentError = nil
        let expectation = self.expectation(description: "")
        
        // Act
        var isSuccess = false
        firebaseUser.resetPassword(for: "test@test.com") { result in
            switch result {
            case .failure:
                XCTFail("Expected success, got failure instead")
            case .success:
                expectation.fulfill()
            }
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
    }
    
    func testGivenError_WhenSignInUser_ThenReturnFailure() {
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseServiceStub.stubbedDocumentError = expectedError
        let expectation = self.expectation(description: "")
        
        // Act
        firebaseUser.signInUser(email: "test@test.com", password: "password") { result in
            switch result {
            case .failure(_):
                expectation.fulfill()
            case .success:
                XCTFail("Expected failure, got success instead")
            }
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testGivenNoError_WhenSignInUser_ThenReturnSuccess() {
        // Arrange
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData]
        
        // Act
        var isSuccess = false
        let expectation = self.expectation(description: "signInUser finishes")
        
        firebaseUser.signInUser(email: "test@test.com", password: "password") { result in
            switch result {
            case .failure:
                XCTFail("Expected success, got failure instead")
            case .success:
                expectation.fulfill()
            } // Mark the expectation as having been fulfilled
        }
        
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
    }
    
    func testGivenError_WhenCreateUser_ThenReturnFailure() {
        // Arrange
        let expectedError = NSError(domain: "", code: -1, userInfo: nil)
        let expectation = self.expectation(description: "")
        firebaseServiceStub.stubbedDocumentError = expectedError
        
        // Act
        firebaseUser.createUser(email: "test@test.com", password: "password", pseudo: "") { result in
            switch result {
            case .failure:
                expectation.fulfill()
            case .success:
                XCTFail("Expected failure, got success instead")
                
            }
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testGivenNoError_WhenCreateUser_ThenReturnSuccess() {
        firebaseServiceStub.stubbedQuerySnapshotDatas = []
        
        // Act
        let expectation = self.expectation(description: "")
        
        firebaseUser.createUser(email: "test@test.com", password: "password", pseudo: "") { result in
            switch result {
            case .failure:
                XCTFail("Expected success, got failure instead")
            case .success:
                expectation.fulfill()
            }
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
        
    }
    
    //-----------------------------------------------------------------------------------
    //                                GET INFO, QUIZZES AND GROUPS
    //-----------------------------------------------------------------------------------
    
    func testGivenError_WhenGetUserInfo_ThenReturnFailure() {
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
    
    func testGivenNoError_WhenGetUserInfo_ThenReturnSuccess() {
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
    
    func testGivenError_WhenGetUserQuizzes_ThenReturnFailure() {
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
    
    func testGivenNoError_WhenGetUserQuizzes_ThenReturnSuccess() {
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
    
    func testGivenError_WhenGetUserGroups_ThenReturnFailure() {
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
    
    func testGivenNoError_WhenGetUserGroups_ThenReturnSuccess() {
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
    
    func testGivenError_WhenSaveImageInStorage_ThenReturnFailure() {
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
    
    func testGivenNoError_WhenSaveImageInStorage_ThenReturnSuccess() {
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
    
    func testGivenError_WhenSaveProfileImage_ThenReturnFailure() {
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
    
    func testGivenNoError_WhenSaveProfileImage_ThenReturnSuccess() {
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
    
    func testGivenError_WhenDeleteProfileImage_ThenReturnFailure() {
        // Arrange
        firebaseServiceStub.stubbedDocumentError =  nil
        let expectation = self.expectation(description: "")
        // Act
        firebaseUser.deleteProfileImageURL() { result in
            switch result {
            case .failure:
                XCTFail("expected success, got failure instead")
            case .success:
                expectation.fulfill()
            }
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testGivenNoError_WhenDeleteProfileImage_ThenReturnSuccess() {
        // Arrange
        firebaseServiceStub.stubbedDocumentError =  NSError(domain: "", code: -1, userInfo: nil)
        let expectation = self.expectation(description: "")
        // Act
        firebaseUser.deleteProfileImageURL() { result in
            switch result {
            case .failure:
                expectation.fulfill()
            case .success:
                XCTFail("expected failure, got succes instead")
            }
            
        }
        // Wait for expectations for a maximum of 5 seconds (you can adjust this time as necessary)
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testGivenError_WhenDownloadProfileImageFromUrl_ThenReturnFailure() {
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
    
    func testGivenNoError_WhenDownloadProfileImageFromUrl_ThenReturnSuccess() {
        // Arrange
        // Arrange
        firebaseServiceStub.stubbedDocumentError = nil
        let expectation = self.expectation(description: "Add group")
        firebaseUser.deleteImageInStorage() { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(_):
                XCTFail("expected success, got failure instead")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGivenError_WhenDeleteImageInStorage_ThenReturnFailure() {
        // Arrange
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        let expectation = self.expectation(description: "Add group")
        firebaseUser.deleteImageInStorage() { result in
            switch result {
            case .success:
                
                XCTFail("expected failure, got succes instead")
            case .failure(_):
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGivenNoError_WhenDeleteImageInStorage_ThenReturnSuccess() {
        // Arrange
        let expectation = self.expectation(description: "Add group")
        firebaseUser.deleteImageInStorage() { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(_):
                XCTFail("expected success, got failure instead")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    
    //-----------------------------------------------------------------------------------
    //                                FRIENDS
    //-----------------------------------------------------------------------------------
    
    
    func testGivenValideData_WhenFetchInvites_ThenReturnNoError() {
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
    
    func testGivenError_WhenFetchInvites_ThenReturnError() {
        // Arrange
        let expectation = self.expectation(description: "Fetch Invites")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData, fakeResponsesData.mockUserData]
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseUser.fetchInvites { invites, error in
            if let error {
                expectation.fulfill()
            } else {
                XCTFail("expected error")
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGivenValideData_WhenSendFriendRequest_ThenReturnSuccess() {
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
    
    func testGivenError_WhenSendFriendRequest_ThenReturnFailure() {
        // Arrange
        let expectation = self.expectation(description: "Send Friend Request")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData]
        firebaseServiceStub.stubbedQuerySnapshotDatas = [fakeResponsesData.mockUsersData]
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseUser.sendFriendRequest(username: "user3") { result in
            switch result {
            case .failure:
                expectation.fulfill()
            case .success:
                XCTFail("expected failure")
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGivenValideData_WhenFetchFriendRequest_ThenReturnsDictAndNoError() {
        // Arrange
        let expectation = self.expectation(description: "Fetch Friend Requests")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData, fakeResponsesData.mockUserData]
        
        
        firebaseUser.fetchFriendRequests(status: .sent) { requests, error in
            if let error {
                XCTFail("expected success")
            } else {
                expectation.fulfill()
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGivenError_WhenFetchFriendRequest_ThenReturnsError() {
        // Arrange
        let expectation = self.expectation(description: "Fetch Friend Requests")
        firebaseServiceStub.stubbedDocumentSnapshots = [fakeResponsesData.mockUserData, fakeResponsesData.mockUserData]
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        
        firebaseUser.fetchFriendRequests(status: .sent) { requests, error in
            if let error {
                expectation.fulfill()
            } else {
                XCTFail("expected failure")
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGivenNoError_WhenAcceptFriendRequest_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenAcceptFriendRequest_ThenReturnsFailure() {
        // Arrange
        let expectation = self.expectation(description: "Accept Friend Request")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseUser.acceptFriendRequest(friendID: "validFriendId", friendUsername: "validUsername") { result in
            switch result {
            case .failure:
                expectation.fulfill()
            case .success:
                XCTFail("expected failure")
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGivenNoError_WhenRejectFriendRequest_ThenReturnsSuccess() {
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
    
    
    func testGivenError_WhenRejectFriendRequest_ThenReturnsFailure() {
        // Arrange
        let expectation = self.expectation(description: "Reject Friend Request")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        firebaseUser.rejectFriendRequest(friendID: "validFriendId") { result in
            switch result {
            case .failure:
                expectation.fulfill()
            case .success:
                XCTFail("expected failure")
            }
        }
        
        // Assert
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testGivenNoError_WhenRemoveFriend_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenRemoveFriend_ThenReturnsFailure() {
        // Arrange
        let expectation = self.expectation(description: "Remove Friend")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
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
    
    
    func testGivenNoError_WhenAddQuiz_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenAddQuiz_ThenReturnsFailure() {
        // Prepare mock and stub
        
        firebaseUser.userQuizzes = []
        let expectation = XCTestExpectation(description: "Get user info success")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        // Test
        firebaseUser.addQuiz(name: "testQuiz", category_id: "categoryId", difficulty: "medium") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(_):
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGivenNoErrorAndValideData_WhenDeleteQuiz_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenDeleteQuiz_ThenReturnsFailure() {
        // Prepare mock and stub
        let quiz = Quiz(id: "", name: "", category_id: "", creator: "", difficulty: "", questions: [:], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        
        let expectation = XCTestExpectation(description: "Get user info success")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        
        // Test
        firebaseUser.deleteQuiz(quiz: firebaseUser.userQuizzes![0]) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(_):
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGivenNoErrorAndValideData_WhenAddQuestionToQuiz_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenAddQuestionToQuiz_ThenReturnsFailure() {
        // Prepare mock and stub
        let quiz = Quiz(id: "", name: "", category_id: "", creator: "", difficulty: "", questions: [:], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        
        let expectation = XCTestExpectation(description: "Get user info success")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        
        // Test
        firebaseUser.addQuestionToQuiz(quiz: firebaseUser.userQuizzes![0], questionText: "Question?", correctAnswer: "Answer", incorrectAnswers: ["Wrong", "", ""], explanation: "Explanation") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(_):
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGivenNoErrorAndValideData_WhenUpdateQuiz_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenUpdateQuiz_ThenReturnsFailure() {
        // Prepare mock and stub
        let quiz = Quiz(id: "id",name: "", category_id: "", creator: "", difficulty: "", questions: [:], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        
        let expectation = XCTestExpectation(description: "Get user info success")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        
        // Test
        firebaseUser.updateQuiz(quizID: "id", newName: "NewName", newCategoryID: "NewCategory", newDifficulty: "easy") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(_):
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGivenNoErrorAndValideData_WhenDeleteQuestionFromQuiz_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenDeleteQuestionFromQuiz_ThenReturnsFailure() {
        // Prepare mock and stub
        let quiz = Quiz(id: "",name: "", category_id: "", creator: "", difficulty: "", questions: [:], average_score: 0, users_completed: 0, code: "")
        firebaseUser.userQuizzes = [quiz]
        let questions = ["questionID": UniversalQuestion(id: "id", category: "", type: "", difficulty: "", question: "", correct_answer: "", incorrect_answers: [], explanation: "")]
        firebaseUser.userQuizzes![0].questions = questions
        
        let expectation = XCTestExpectation(description: "Get user info success")
        firebaseServiceStub.stubbedDocumentError = NSError(domain: "", code: -1, userInfo: nil)
        
        // Test
        firebaseUser.deleteQuestionFromQuiz(quiz: firebaseUser.userQuizzes![0], questionId: "questionID") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(_):
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGivenNoErrorAndValideData_WhenUpdateQuestionInQuiz_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenUpdateQuestionInQuiz_ThenReturnsFalure() {
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
    
    func testGivenNoErrorAndValideData_WhenFetchGroupMembers_ThenReturnsSuccess(){
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
    
    func testGivenError_WhenFetchGroupMembers_ThenReturnsFailure(){
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
    func testGivenNoErrorAndValideData_WhenDeleteGroup_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenDeleteGroup_ThenReturnsFailure() {
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
    func testGivenNoError_WhenAddGroup_ThenReturnsSuccess() {
        
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
    
    func testGivenError_WhenAddGroup_ThenReturnsFailure() {
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
    func testGivenNoError_WhenUpdateGroupNalme_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenUpdateGroupNalme_ThenReturnsFailure() {
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
    func testGivenNoError_WhenAddNewMembersToGroup_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenAddNewMembersToGroup_ThenReturnsFailure() {
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
    func testGivenNoError_WhenRemoveMemebrsFromGroup_ThenReturnsSuccess() {
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
    
    func testGivenError_WhenRemoveMemebrsFromGroup_ThenReturnsFailure() {
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
    func testGivenNoErrorAndEmptyResponse_WhenGenerateUniqueCode_ThenReturnsSuccess() {
        firebaseServiceStub.stubbedQuerySnapshotDatas = [[[:]]]
        
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
    
    func testGivenError_WhenGenerateUniqueCode_ThenReturnsFailure() {
        firebaseServiceStub.stubbedQuerySnapshotDatas = [[[:]]]
        firebaseServiceStub.stubbedDocumentError = NSError()
        let expectation = self.expectation(description: "Generate unique code")
        firebaseUser.generateUniqueCode() { result  in
            switch result {
            case .failure(_):
                expectation.fulfill()
            case .success(_):
                XCTFail("Expected failure")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGivenNotEmptyData_WhenGenerateUniqueCode_ThenReturnsFailure() {
        firebaseServiceStub.stubbedQuerySnapshotDatas = [[fakeResponsesData.mockQuizData]]
        
        let expectation = self.expectation(description: "Generate unique code")
        firebaseUser.generateUniqueCode() { result  in
            switch result {
            case .failure(_):
                XCTFail("Expected success")
            case .success(_):
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

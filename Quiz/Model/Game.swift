//
//  Game.swift
//  Quizz CultureG
//
//  Created by Guillaume Bourlart on 21/04/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class Game {
    
    static let shared = Game()
    var apiManager = OpenTriviaDatabaseManager(service: Service(networkRequest: AlamofireNetworkRequest())) // API manager reference (for TriviaDB)
    private var firebaseService: FirebaseServiceProtocol
    init(firebaseService: FirebaseServiceProtocol = FirebaseService()) {
        self.firebaseService = firebaseService
    }
    var currentUserId: String? { return firebaseService.currentUserID } // get current UID
    
    
    //-----------------------------------------------------------------------------------
    //                                 Competitive
    //-----------------------------------------------------------------------------------
    
    // Function to search a competitive room
    func searchCompetitiveRoom(completion: @escaping (Result<String, Error>) -> Void ) {
        guard (firebaseService.currentUserID) != nil else {
            completion(.failure(FirebaseError.noUserConnected))
            return
        }
        
        let conditions: [FirestoreCondition] = [
            .isEqualTo(FirestoreFields.status, "waiting"),
            .isEqualTo(FirestoreFields.Lobby.competitive, true)
        ]

        firebaseService.getDocuments(in: FirestoreFields.lobbyCollection, whereFields: conditions) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let lobbyData):
                if !lobbyData.isEmpty {
                    guard let lobbyId = lobbyData.first?[FirestoreFields.id] as? String else {
                        completion(.failure(FirebaseError.unableToDecodeLobbyId))
                        return
                    }
                    self.joinCompetitiveRoom(lobbyId: lobbyId) { result in
                        switch result {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success():
                            completion(.success(lobbyId))
                        }
                    }
                } else {
                    self.createCompetitiveRoom() { result in
                        switch result {
                        case .failure(let error):
                            completion(.failure(error))
                        case .success(let lobbyId):
                            completion(.success(lobbyId))
                        }
                    }
                }
            }
        }
    }

    // Function to join a competitive room from it's lobby ID
    func joinCompetitiveRoom(lobbyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseError.noUserConnected))
            return
        }
        
        firebaseService.updateDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId, data: [FirestoreFields.status: "matched"]) { error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
                self.firebaseService.getDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let lobbyData):
                        guard !lobbyData.isEmpty else { return }
                        var players = lobbyData[FirestoreFields.Lobby.players] as! [String]
                        players.append(currentUserId)
                        
                        self.createQuestionsForGame(quizId: nil, category: nil, difficulty: nil, with: lobbyId, competitive: true, players: players) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success(_):
                                completion(.success(()))
                            }
                        }
                    }
                
            }
        }
    }
    // Function to create competitive room
    func createCompetitiveRoom(completion: @escaping (Result<String, Error>) -> Void ) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseError.noUserConnected)); return
        }

        let newLobbyId = UUID().uuidString
        
        firebaseService.setData(in: FirestoreFields.lobbyCollection, documentId: newLobbyId, data: [FirestoreFields.creator: currentUserId, FirestoreFields.Lobby.competitive: true, FirestoreFields.status: "waiting",  FirestoreFields.Lobby.players: [currentUserId]]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(newLobbyId))
            }
        }
    }

    // Function to get questions from a quiz ID (when launching a custom quiz) or from gameID when game starts
    func getQuestions(quizId: String? ,gameId: String?, completion: @escaping (Result<[UniversalQuestion], Error>) -> Void) {
        guard firebaseService.currentUserID != nil else {
            completion(.failure(FirebaseError.noUserConnected))
            return
        }
        
        var collection = ""
        var id = ""
        if let quizId = quizId {
            collection = FirestoreFields.quizzesCollection
            id = quizId
        } else if let gameId = gameId {
            collection = FirestoreFields.gamesCollection
            id = gameId
        }
        
        firebaseService.getDocument(in: collection, documentId: id) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let gameData):
                guard  !gameData.isEmpty else {
                    completion(.failure(FirebaseError.documentDoesntExist))
                    return
                }
                
                guard let questionsData = gameData[FirestoreFields.Game.questions] as? [String: [String: Any]] else {
                    completion(.failure(FirebaseError.failedToGetData))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    var questions = [UniversalQuestion]()
                    
                    for (questionID, questionData) in questionsData {
                        let jsonData = try JSONSerialization.data(withJSONObject: questionData, options: [])
                        var question = try decoder.decode(UniversalQuestion.self, from: jsonData)
                        question.id = questionID
                        questions.append(question)
                    }

                    completion(.success(questions))
                    
                } catch let error {
                    completion(.failure(error))
                }
            }
        }
    }
    //-----------------------------------------------------------------------------------
    //                                 Quick play
    //-----------------------------------------------------------------------------------
    
    // Function to create a private room
    func createRoom(quizID: String?, completion: @escaping (Result<String, Error>) -> Void ) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseError.noUserConnected))
            return
        }
        let newLobbyId = UUID().uuidString
        FirebaseUser.shared.generateUniqueCode { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let code):
                var data = [
                    FirestoreFields.creator: currentUserId,
                    FirestoreFields.Lobby.competitive: false,
                    FirestoreFields.status: "Private",
                    FirestoreFields.Lobby.joinCode: code,
                    FirestoreFields.Lobby.invitedUsers: [String](),
                    FirestoreFields.Lobby.invitedGroups: [String](),
                    FirestoreFields.Lobby.players: [currentUserId]
                ] as [String : Any]
                
                if let quizID = quizID {
                    data[FirestoreFields.Lobby.quizId] = quizID
                }
                    
                self.firebaseService.setData(in: FirestoreFields.lobbyCollection, documentId: newLobbyId, data: data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success((newLobbyId)))
                    }
                }
            }
        }
    }

    // Funcrtion to invite a pplayer in a private room
    func invitePlayerInRoom(lobbyId: String,invited_players: [String], invited_groups: [String], completion: @escaping (Result<Void, Error>) -> Void ){
        guard (firebaseService.currentUserID) != nil else {
            completion(.failure(FirebaseError.noUserConnected)); return
        }
        let data = [
            FirestoreFields.Lobby.invitedUsers: invited_players,
            FirestoreFields.Lobby.invitedGroups: invited_groups
        ] as [String : Any]
        
        firebaseService.setDataWithMerge(in: FirestoreFields.lobbyCollection, documentId: lobbyId, data: data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            }else{
                completion(.success(()))
            }
        }
    }
    
    // Function to delete current room
    func deleteCurrentRoom(lobbyId: String, completion: @escaping (Result<Void, Error>) -> Void ) {
        guard firebaseService.currentUserID != nil else {
            completion(.failure(FirebaseError.noUserConnected)); return
        }
        
        firebaseService.deleteDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    
    // Function to join a private room
    func joinRoom(lobbyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseError.noUserConnected))
            return
        }
        firebaseService.getDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                var players = (data[FirestoreFields.Lobby.players] as? [String]) ?? []
                players.append(currentUserId)
                
                guard var invitedPlayers = data[FirestoreFields.Lobby.invitedUsers] as? [String] else {
                    completion(.failure(FirebaseError.failedToGetPlayers))
                    return
                }
                if let index = invitedPlayers.firstIndex(of: currentUserId) {
                    invitedPlayers.remove(at: index)
                }
                
                self.firebaseService.updateDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId, data: [FirestoreFields.Lobby.players: players]) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    self.firebaseService.updateDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId, data: [FirestoreFields.Lobby.invitedUsers: invitedPlayers]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            Game.shared.deleteInvite(inviteId: lobbyId) { result in
                            switch result {
                            case .failure(let error): completion(.failure(error))
                                case .success: completion(.success(()))
                                }
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    
    // Function to join a room with its code
    func joinWithCode(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard (firebaseService.currentUserID) != nil else {
            completion(.failure(FirebaseError.noUserConnected))
            return
        }

        let condition: [FirestoreCondition] = [.isEqualTo(FirestoreFields.Lobby.joinCode, code)]
        
        firebaseService.getDocuments(in: FirestoreFields.lobbyCollection, whereFields: condition) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                guard !data.isEmpty, let lobbyData = data.first, let lobbyId = lobbyData["id"] as? String else {
                    completion(.failure(FirebaseError.noDataInResponse))
                    return
                }

                // Now join the lobby
                self.joinRoom(lobbyId: lobbyId, completion: { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        completion(.success(lobbyId))
                    }
                })
            }
        }
    }
    
    // Function to delete invite from invites
    func deleteInvite(inviteId: String,  completion: @escaping (Result<String, Error>) -> Void){
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseError.noUserConnected))
            return
        }
        
        firebaseService.getDocument(in: FirestoreFields.usersCollection, documentId: currentUserId) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                guard let invites = data[FirestoreFields.User.invites] as? [String: String] else {
                    completion(.failure(FirebaseError.failedToGetData))
                    return
                }
                var newInvites = invites
                for (key, value) in newInvites {
                    if value == inviteId {
                        newInvites.removeValue(forKey: key)
                    }
                }

                self.firebaseService.updateDocument(in: FirestoreFields.usersCollection, documentId: currentUserId, data: [FirestoreFields.User.invites: newInvites]) { error in
                    if let error = error {
                        completion(.failure(error))
                    }
                    else {
                        if let key = FirebaseUser.shared.userInfo?.invites.first(where: { $1 == inviteId })?.key {
                                FirebaseUser.shared.userInfo?.invites.removeValue(forKey: key)
                            }
                        completion(.success(inviteId))
                    }
                }
            }
        }
    }

    
    
    // Function to leave a private room
    func leaveLobby(lobbyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        firebaseService.getDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                guard var players = data[FirestoreFields.Lobby.players] as? [String], let currentUserId = self.firebaseService.currentUserID else {
                    completion(.failure(FirebaseError.failedToGetPlayers))
                    return
                }
                if let index = players.firstIndex(of: currentUserId) {
                    players.remove(at: index)
                }
                
                self.firebaseService.updateDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId, data: [FirestoreFields.Lobby.players: players]) { error in
                    if let error = error {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    //-----------------------------------------------------------------------------------
    //                                 General
    //-----------------------------------------------------------------------------------
    
    // Function to create question of the game, depending of it is a custom quiz or a TriviaDB quiz
    func createQuestionsForGame(quizId: String?, category: Int?, difficulty: String?, with documentId: String?, competitive: Bool, players: [String], completion: @escaping (Result<String, Error>) -> Void) {
        guard (firebaseService.currentUserID) != nil else {
            completion(.failure(FirebaseError.noUserConnected)); return
        }
        if let quizId = quizId {
            self.getQuestions(quizId: quizId, gameId: nil) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let questions):
                    self.createGame(questions: questions, with: documentId, competitive: competitive, players: players) { result in
                        switch result {
                        case .failure(let error): completion(.failure(error))
                        case .success(let gameId): completion(.success(gameId))
                        }
                    }
                }
            }
        } else{
            self.apiManager.fetchQuestions(inCategory: category, difficulty: difficulty) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let questions):
                    self.createGame(questions: questions, with: documentId, competitive: competitive, players: players) { result in
                        switch result {
                        case .failure(let error): completion(.failure(error))
                        case .success(let gameId): completion(.success(gameId))
                        }
                    }
                }
            }
        }
    }
    
    // Function to create a game, with it's questions
    func createGame(questions: [UniversalQuestion], with documentId: String?, competitive: Bool, players: [String], completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseError.noUserConnected)); return
        }
        
        let gameId = documentId ?? UUID().uuidString
        
        var questionsDict = [String: [String: Any]]()
        for var question in questions {
            question.id = UUID().uuidString
            questionsDict[question.id!] = question.dictionary
        }
        
        let playersArray = players
        
        let gameData: [String: Any] = [
            FirestoreFields.creator: currentUserId,
            FirestoreFields.status: "waiting",
            FirestoreFields.Game.players: playersArray,
            FirestoreFields.date: FieldValue.serverTimestamp(),
            FirestoreFields.Game.competitive: competitive,
            FirestoreFields.Game.questions: questionsDict
        ]
        
        // Perform create game and delete lobby operation
        self.firebaseService.setData(in: FirestoreFields.gamesCollection, documentId: gameId, data: gameData, completion: { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let documentId = documentId else { completion(.success(gameId)); return }
            // If we pass the guard let, then the game is not in SOLO and we can update de lobby document
            let lobbyData: [String: Any] = [
                FirestoreFields.status: "started"
            ]
            self.firebaseService.updateDocument(in: FirestoreFields.lobbyCollection, documentId: documentId, data: lobbyData) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(gameId))
            }
            
        })

    }
    
        
    // Function to leave a game
    func leaveGame(gameId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseError.noUserConnected)); return
        }
        
        firebaseService.getDocument(in: FirestoreFields.gamesCollection, documentId: gameId) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                guard var players = data[FirestoreFields.Game.players] as? [String] else {
                    completion(.failure(FirebaseError.failedToGetPlayers))
                    return
                }
                if let index = players.firstIndex(of: currentUserId) {
                    players.remove(at: index)
                }
                self.firebaseService.updateDocument(in: FirestoreFields.gamesCollection, documentId: gameId, data: [FirestoreFields.Game.players: players]) { error in
                    if let error = error {
                        completion(.failure(error))
                    }else{
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    
    
    
    
    //-----------------------------------------------------------------------------------
    //                                 GAME DATA
    //-----------------------------------------------------------------------------------
    
    // Function to check if a game exist
    func checkIfGameExist(gameID: String, completion: @escaping (Result<String, Error>) -> Void){
        guard firebaseService.currentUserID != nil else {
            completion(.failure(FirebaseError.noUserConnected)); return
        }
        
        firebaseService.getDocument(in: "games", documentId: gameID) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                guard let gameId = data["id"] as? String, let status = data["status"] as? String, status == "waiting" else {
                    completion(.failure(FirebaseError.documentDoesntExist)); return
                }
                completion(.success(gameId))
            }
        }
    }
    
    // Function to get user's completed games
    func getCompletedGames(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseError.noUserConnected)); return
        }
        
        let conditions: [FirestoreCondition] = [
            .isEqualTo(FirestoreFields.status, "waiting"),
            .arrayContains(FirestoreFields.Game.players, currentUserId)
        ]
        
        firebaseService.getDocuments(in: FirestoreFields.gamesCollection, whereFields: conditions) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let gamesData):
                guard !gamesData.isEmpty else {
                    completion(.success(())); return
                }
                
                do {
                    let convertedGameDataWithDate = gamesData.map { self.convertTimestampsToDate(in: $0) }
                    let jsonData = try JSONSerialization.data(withJSONObject: convertedGameDataWithDate, options: [])
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let completedGames = try decoder.decode([GameData].self, from: jsonData)
                    
                    FirebaseUser.shared.History = completedGames
                    completion(.success(()))
                }  catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Function to get a game data from it's gameID
    func getGameData(gameId: String, completion: @escaping (Result<GameData, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else {
            completion(.failure(FirebaseError.noUserConnected)); return
        }
        
        firebaseService.getDocument(in: FirestoreFields.gamesCollection, documentId: gameId) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let gameData):
                do {
                    let convertedDataWithDate = self.convertTimestampsToDate(in: gameData)
                    let jsonData = try JSONSerialization.data(withJSONObject: convertedDataWithDate, options: [])
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let gameData = try decoder.decode(GameData.self, from: jsonData)
                    
                    FirebaseUser.shared.History?.append(gameData)
                    completion(.success(gameData))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // Function to save player stats of the game
    func saveStats(finalScore: Int, userAnswers: [String: UserAnswer], gameID: String, completion: @escaping (Result<Void, Error>) -> Void ) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(FirebaseError.noUserConnected))
            return
        }
        
        var answersData: [String: Any] = [:]
        for (key, userAnswer) in userAnswers {
            answersData[key] = userAnswer.dictionary
        }
        
        let data: [String: Any] = [
            "\(FirestoreFields.Game.userAnswers)": [currentUserId: answersData],
            "\(FirestoreFields.Game.finalScores)": [currentUserId: finalScore]
        ]
        
        self.firebaseService.setDataWithMerge(in: FirestoreFields.gamesCollection, documentId: gameID, data: data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                if var game = FirebaseUser.shared.History?.first(where: { $0.id == gameID }) {
                    game.user_answers?[currentUserId] = userAnswers
                }
                completion(.success(()))
            }
        }
    }
    
    
    
    //-----------------------------------------------------------------------------------
    //                                 LISTENER FOR GAME STARTING
    //-----------------------------------------------------------------------------------
    
    // Function to listen for change in a document
    func ListenForChangeInDocument(in collection: String, documentId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) -> ListenerRegistration {
        return firebaseService.addDocumentSnapshotListener(in: collection, documentId: documentId) { result in
            switch result {
            case .success(let data):
                
                completion(.success(data))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Function to convert timestamps to data
    func convertTimestampsToDate(in data: [String: Any]) -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        var convertedData = data
        
        for (key, value) in data {
            if let timestamp = value as? Timestamp {
                let date = timestamp.dateValue()
                let dateString = dateFormatter.string(from: date)
                convertedData[key] = dateString
            } else if let subdocument = value as? [String: Any] {
                convertedData[key] = convertTimestampsToDate(in: subdocument)
            }
        }
        return convertedData
    }
}

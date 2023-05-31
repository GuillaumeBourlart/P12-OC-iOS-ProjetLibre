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
    
    var apiManager = OpenTriviaDatabaseManager(service: Service(networkRequest: AlamofireNetworkRequest()))
    
    private var firebaseService: FirebaseServiceProtocol
    
    init(firebaseService: FirebaseServiceProtocol = FirebaseService()) {
        self.firebaseService = firebaseService
    }
    var currentUserId: String? { return firebaseService.currentUserID }
    
    
    //-----------------------------------------------------------------------------------
    //                                 Competitive
    //-----------------------------------------------------------------------------------
    
    func searchCompetitiveRoom(completion: @escaping (Result<String, Error>) -> Void ) {
        guard (firebaseService.currentUserID) != nil else {
            completion(.failure(MyError.noUserConnected)); return
        }
        
        let conditions: [FirestoreCondition] = [.isEqualTo(FirestoreFields.status, "waiting"), .isEqualTo(FirestoreFields.Lobby.competitive, true)]
        firebaseService.getDocuments(in: FirestoreFields.lobbyCollection, whereFields: conditions) { lobbyData, error in
            if let error = error {
                completion(.failure(error))
            } else if let lobbyData = lobbyData, !lobbyData.isEmpty {
                let lobbyId = lobbyData.first![FirestoreFields.id] as! String
                
                self.joinCompetitiveRoom(lobbyId: lobbyId) { success in
                    switch success {
                    case .success():
                        completion(.success(lobbyId))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } else {
                self.createCompetitiveRoom() { success in
                    switch success {
                    case .success(let lobbyId):
                        completion(.success(lobbyId))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func joinCompetitiveRoom(lobbyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected)); return
        }
        
        firebaseService.updateDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId, data: [FirestoreFields.status: "matched"]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.firebaseService.getDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId) { lobbyData, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let lobbyData = lobbyData else { return }
                let creator = lobbyData[FirestoreFields.creator] as! String
                let players = [creator]
                
                self.createGame(category: nil, difficulty: nil, with: lobbyId, competitive: true, players: players) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(_):
                        self.deleteCurrentRoom(lobbyId: lobbyId) { result in
                            switch result {
                            case .failure(let error): completion(.failure(error))
                            case .success(): completion(.success(()))
                            }
                        }
                    }
                }
            }
        }
    }

    func createCompetitiveRoom(completion: @escaping (Result<String, Error>) -> Void ) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected)); return
        }

        let newLobbyId = UUID().uuidString
        firebaseService.setData(in: FirestoreFields.lobbyCollection, documentId: newLobbyId, data: [FirestoreFields.id: newLobbyId, FirestoreFields.creator: currentUserId, FirestoreFields.Lobby.competitive: true, FirestoreFields.status: "waiting"]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(newLobbyId))
            }
        }
    }

    

    

    func getQuestions(gameId: String, completion: @escaping (Result<[UniversalQuestion], Error>) -> Void) {
        guard firebaseService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        firebaseService.getDocument(in: FirestoreFields.gamesCollection, documentId: gameId) { gameData, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let gameData = gameData else {
                completion(.failure(MyError.documentDoesntExist))
                return
            }
            
            guard let questionsData = gameData[FirestoreFields.Game.questions] as? [String: [String: Any]] else {
                completion(.failure(MyError.failedToGetData))
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
    
    //-----------------------------------------------------------------------------------
    //                                 Quick play
    //-----------------------------------------------------------------------------------
    
    
    func createRoom(completion: @escaping (Result<String, Error>) -> Void ) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected)); return
        }
        let newLobbyId = UUID().uuidString
        FirebaseUser.shared.generateUniqueCode { code, error in
            if let error = error {
                completion(.failure(error))
            }
            else if let code = code {
                let data = [
                    FirestoreFields.id: newLobbyId,
                    FirestoreFields.creator: currentUserId,
                    FirestoreFields.Lobby.competitive: false,
                    FirestoreFields.status: "Private",
                    FirestoreFields.Lobby.joinCode: code,
                    FirestoreFields.Lobby.invitedUsers: [String](),
                    FirestoreFields.Lobby.invitedGroups: [String](),
                    FirestoreFields.Lobby.players: [String]()
                ] as [String : Any]
                    
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

    func invitePlayerInRoom(lobbyId: String,invited_players: [String], invited_groups: [String], completion: @escaping (Result<Void, Error>) -> Void ){
        guard (firebaseService.currentUserID) != nil else {
            completion(.failure(MyError.noUserConnected)); return
        }
        let data = [
            FirestoreFields.Lobby.invitedUsers: invited_players,
            FirestoreFields.Lobby.invitedGroups: invited_groups
        ]
        
        firebaseService.updateDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId, data: data) { error in
            if let error = error {
                completion(.failure(error))
            }
            completion(.success(()))
        }
    }
    
    func deleteCurrentRoom(lobbyId: String, completion: @escaping (Result<Void, Error>) -> Void ) {
        guard firebaseService.currentUserID != nil else {
            completion(.failure(MyError.noUserConnected)); return
        }
        
        firebaseService.deleteDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    

    func joinRoom(lobbyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        firebaseService.getDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Add player to "players"
            var players: [String] = (data![FirestoreFields.Lobby.players] as? [String]) ?? []
            players.append(currentUserId)
            
            // Remove player from "invited_players"
            guard let invitedPlayers = data?[FirestoreFields.Lobby.invitedUsers] as? [String] else {
                completion(.failure(MyError.generalError))
                return
            }
            let updatedPlayers = invitedPlayers.filter { $0 != currentUserId }
            
            self.firebaseService.updateDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId, data: [FirestoreFields.Lobby.players: players]) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                self.firebaseService.updateDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId, data: [FirestoreFields.Lobby.invitedUsers: updatedPlayers]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        // The player has joined the lobby successfully
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    
    func joinWithCode(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard (firebaseService.currentUserID) != nil else {
            completion(.failure(MyError.noUserConnected))
            return
        }

        let condition: [FirestoreCondition] = [.isEqualTo(FirestoreFields.Lobby.joinCode, code)]
        
        firebaseService.getDocuments(in: FirestoreFields.lobbyCollection, whereFields: condition) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, !data.isEmpty, let lobbyId = data.first?[FirestoreFields.id] as? String else {
                // Handle the case where the data is not as expected
                return
            }

            // Now join the lobby
            self.joinRoom(lobbyId: lobbyId) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success():
                        completion(.success(lobbyId))
                    }
                }
        }
    }

    func deleteInvite(inviteId: String,  completion: @escaping (Result<String, Error>) -> Void){
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected)); return
        }
        
        firebaseService.getDocument(in: FirestoreFields.usersCollection, documentId: currentUserId) { data, error in
            if let error = error {
                completion(.failure(error))
            }
            else if let invites = data![FirestoreFields.User.invites] as? [String: String] {
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
                        completion(.success(inviteId))
                    }
                }
            }
        }
    }

    func leaveLobby(lobbyId: String, completion: @escaping (Error?) -> Void) {
        firebaseService.getDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId) { data, error in
            if let error = error {
                completion(error)
            }
            guard let players = data?[FirestoreFields.Lobby.players] as? [String], let currentUserId = self.firebaseService.currentUserID else {
                completion(MyError.generalError)
                return
            }
            let updatedPlayers = players.filter { $0 != currentUserId }
            self.firebaseService.updateDocument(in: FirestoreFields.lobbyCollection, documentId: lobbyId, data: [FirestoreFields.Lobby.players: updatedPlayers]) { error in
                completion(error)
            }
        }
    }
    
    //-----------------------------------------------------------------------------------
    //                                 General
    //-----------------------------------------------------------------------------------
    
    func createGame(category: Int?, difficulty: String?, with documentId: String?, competitive: Bool, players: [String], completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected)); return
        }
        self.apiManager.fetchQuestions(inCategory: category, difficulty: difficulty) { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let questions):
                let gameId = documentId ?? UUID().uuidString
                
                var questionsDict = [String: [String: Any]]()
                for var question in questions {
                    question.id = UUID().uuidString
                    questionsDict[question.id!] = question.dictionary
                }
                
                var playersArray = players
                playersArray.append(currentUserId)
                
                let gameData: [String: Any] = [
                    FirestoreFields.id: gameId,
                    FirestoreFields.creator: currentUserId,
                    FirestoreFields.status: "waiting",
                    FirestoreFields.Game.players: playersArray,
                    FirestoreFields.date: FieldValue.serverTimestamp(),
                    FirestoreFields.Game.competitive: competitive,
                    FirestoreFields.Game.questions: questionsDict
                ]
                
                self.firebaseService.setData(in: FirestoreFields.gamesCollection, documentId: gameId, data: gameData) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    completion(.success(gameId))
                    
                }
            }
        }
    }
    
    
    func leaveGame(gameId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard (firebaseService.currentUserID) != nil else {
            completion(.failure(MyError.noUserConnected)); return
        }
        
        firebaseService.getDocument(in: FirestoreFields.gamesCollection, documentId: gameId) { data, error in
            if let error = error {
                completion(.failure(error))
            }
            
            guard let players = data?[FirestoreFields.Game.players] as? [String], let currentUserId = self.firebaseService.currentUserID else {
                completion(.failure(MyError.generalError))
                return
            }
            
            let updatedPlayers = players.filter { $0 != currentUserId }
            self.firebaseService.updateDocument(in: FirestoreFields.gamesCollection, documentId: gameId, data: [FirestoreFields.Game.players: updatedPlayers]) { error in
                if let error = error {
                    completion(.failure(error))
                }else{
                    completion(.success(()))
                }
            }
        }
    }
    
    
    //-----------------------------------------------------------------------------------
    //                                 GAME DATA
    //-----------------------------------------------------------------------------------
    
    
    
    
    func getCompletedGames(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(MyError.noUserConnected)); return }
        
        let conditions: [FirestoreCondition] = [
            .isEqualTo(FirestoreFields.status, "completed"),
            .arrayContains(FirestoreFields.Game.players, currentUserId)
        ]
        
        firebaseService.getDocuments(in: FirestoreFields.gamesCollection, whereFields: conditions) { gameData, error in
            if let error = error {
                completion(.failure(error))
            } else if let gameData = gameData, !gameData.isEmpty {
                do {
                    let convertedGameDataWithDate = gameData.map { self.convertTimestampsToDate(in: $0) }
                    let jsonData = try JSONSerialization.data(withJSONObject: convertedGameDataWithDate, options: [])
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let completedGames = try decoder.decode([GameData].self, from: jsonData)
                    
                    FirebaseUser.shared.History = completedGames
                    completion(.success(()))
                }  catch {
                    completion(.failure(error))
                }
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getGameData(gameId: String, completion: @escaping (Result<GameData, Error>) -> Void) {
        guard firebaseService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        firebaseService.getDocument(in: FirestoreFields.gamesCollection, documentId: gameId) { gameData, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let gameData = gameData else {
                completion(.failure(MyError.documentDoesntExist))
                return
            }
            
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
    
    
    func saveStats(finalScore: Int, userAnswers: [String: UserAnswer], gameID: String, completion: @escaping (Result<Void, Error>) -> Void ) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        var answers: [String: UserAnswer] = [:]
        var answersData: [String: Any] = [:]
        for (key, userAnswer) in userAnswers {
            answersData[key] = userAnswer.dictionary
            answers[key] = UserAnswer(selected_answer: userAnswer.selected_answer, points: userAnswer.points)
        }
        
        firebaseService.getDocument(in: "games", documentId: gameID) { data, error in
            if let error = error {
                print(error)
            }
            var finalScores = data!["final_scores"] as? [String: Int] ?? [:]
            finalScores[currentUserId] = finalScore
            let data: [String: Any] = [
                "\(FirestoreFields.Game.userAnswers).\(currentUserId)": answersData,
                FirestoreFields.status: "completed",
                "\(FirestoreFields.Game.finalScores)": finalScores
            ]
            
            self.firebaseService.updateDocument(in: FirestoreFields.gamesCollection, documentId: gameID, data: data) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    if var game = FirebaseUser.shared.History?.first(where: { $0.id == gameID }) {
                        game.user_answers[currentUserId] = answers
                        
                    }
                    completion(.success(()))
                }
            }
        }
    }
    
    
    
    //-----------------------------------------------------------------------------------
    //                                 LISTENER FOR GAME STARTING
    //-----------------------------------------------------------------------------------
    
    
    func ListenForChangeInDocument(in collection: String, documentId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) -> ListenerRegistration {
        let listener = firebaseService.addDocumentSnapshotListener(in: collection, documentId: documentId) { result in
            switch result {
            case .success(let data):
                
                completion(.success(data))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return listener
    }
    
    func ListenForGameFound(completion: @escaping (Result<String, Error>) -> Void) -> ListenerRegistration  {
        let listener = firebaseService.addCollectionSnapshotListener(in: FirestoreFields.gamesCollection) { result in
            switch result {
            case .success(let documentsData):
                for data in documentsData {
                    if let players = data[FirestoreFields.Game.players] as? [String],
                       let status = data[FirestoreFields.status] as? String,
                       status == "waiting",
                       let gameId = data[FirestoreFields.id] as? String,
                       players.contains(self.firebaseService.currentUserID!) {
                        completion(.success(gameId))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return listener
    }
    
   
    
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

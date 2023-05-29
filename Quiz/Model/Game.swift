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
    
    var difficulty: String?
    var category: Int?
    var currentLobbyId: String?
    
    
    //-----------------------------------------------------------------------------------
    //                                 GAME CREATION
    //-----------------------------------------------------------------------------------
    
    func searchCompetitiveRoom(completion: @escaping (Result<Void, Error>) -> Void ) {
        guard (firebaseService.currentUserID) != nil else {
            completion(.failure(MyError.noUserConnected)); return
        }
        
        let conditions: [FirestoreCondition] = [.isEqualTo("status", "waiting"), .isEqualTo("competitive", true)]
        firebaseService.getDocuments(in: "lobby", whereFields: conditions) { lobbyData, error in
            if let error = error {
                completion(.failure(error))
            } else if let lobbyData = lobbyData, !lobbyData.isEmpty {
                let lobbyId = lobbyData.first!["id"] as! String
                self.currentLobbyId = lobbyId
                self.joinCompetitiveRoom(lobbyId: lobbyId) { success in
                    switch success {
                    case .success():
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } else {
                self.createCompetitiveRoom() { success in
                    switch success {
                    case .success():
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func createCompetitiveRoom(completion: @escaping (Result<Void, Error>) -> Void ) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected)); return
        }

        let newLobbyId = UUID().uuidString
        firebaseService.setData(in: "lobby", documentId: newLobbyId, data: ["id": newLobbyId, "creator": currentUserId, "competitive": true, "status": "waiting"]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.currentLobbyId = newLobbyId
                completion(.success(()))
            }
        }
    }
    
    func deleteCurrentRoom(completion: @escaping (Result<Void, Error>) -> Void ) {
        guard firebaseService.currentUserID != nil else {
            completion(.failure(MyError.noUserConnected)); return
        }
        guard let lobbyId = currentLobbyId else {
            completion(.failure(MyError.noCurrentLobby))
            return
        }
        
        firebaseService.deleteDocument(in: "lobby", documentId: lobbyId) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.currentLobbyId = nil
                completion(.success(()))
            }
        }
        
        
    }
    
    func createGame(competitive: Bool, players: [String], completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected)); return
        }
        self.apiManager.fetchQuestions(inCategory: category, difficulty: difficulty) { result in
            switch result {
            case .failure(let error): completion(.failure(error))
            case .success(let questions):
                let gameId = UUID().uuidString
                
                var questionsDict = [String: [String: Any]]()
                for var question in questions {
                    question.id = UUID().uuidString
                    questionsDict[question.id!] = question.dictionary
                }
                
                let gameData: [String: Any] = [
                    "id": gameId,
                    "name": "Quizz entre amis",
                    "creator": currentUserId,
                    "status": "waiting",
                    "players": players,
                    "date": FieldValue.serverTimestamp(),
                    "competitive": competitive,
                    "questions": questionsDict
                ]
                
                self.firebaseService.setData(in: "games", documentId: gameId, data: gameData) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    completion(.success(gameId))
                    
                }
            }
        }
    }
    
    func getQuestions(gameId: String, completion: @escaping (Result<[UniversalQuestion], Error>) -> Void) {
        guard firebaseService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        firebaseService.getDocument(in: "games", documentId: gameId) { gameData, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let gameData = gameData else {
                completion(.failure(MyError.documentDoesntExist))
                return
            }
            
            guard let questionsData = gameData["questions"] as? [String: [String: Any]] else {
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
    //                                 Rooms
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
            else if code != nil, let code = code {
                let data = [
                    "id": newLobbyId,
                    "creator": currentUserId,
                    "competitive": false,
                    "status": "Private",
                    "join_code": code,
                    "invited_players": [],
                    "invited_groups": [],
                    "players": []
                ] as [String : Any]
                    
                
                self.firebaseService.setData(in: "lobby", documentId: newLobbyId, data: data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.currentLobbyId = newLobbyId
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
            "invited_players": invited_players,
            "invited_groups": invited_groups
        ]
        
        firebaseService.updateDocument(in: "lobby", documentId: lobbyId, data: data) { error in
            if let error = error {
                completion(.failure(error))
            }
            completion(.success(()))
        }
    }
    
    
    
    func joinCompetitiveRoom(lobbyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected)); return
        }
        
        firebaseService.updateDocument(in: "lobby", documentId: lobbyId, data: ["status": "matched"]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.firebaseService.getDocument(in: "lobby", documentId: lobbyId) { lobbyData, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let lobbyData = lobbyData else { return }
                let creator = lobbyData["creator"] as! String
                let players = [creator, currentUserId]
                
                self.createGame(competitive: true, players: players) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(_):
                        self.deleteCurrentRoom() { result in
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
    
    func joinRoom(lobbyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }
        
        firebaseService.getDocument(in: "lobby", documentId: lobbyId) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Add player to "players"
            var players: [String] = (data!["players"] as? [String]) ?? []
            players.append(currentUserId)
            
            // Remove player from "invited_players"
            guard let invitedPlayers = data?["invited_players"] as? [String] else {
                completion(.failure(MyError.generalError))
                return
            }
            let updatedPlayers = invitedPlayers.filter { $0 != currentUserId }
            
            self.firebaseService.updateDocument(in: "lobby", documentId: lobbyId, data: ["players": players]) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                self.firebaseService.updateDocument(in: "lobby", documentId: lobbyId, data: ["invited_players": updatedPlayers]) { error in
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
        guard let currentUserId = firebaseService.currentUserID else {
            completion(.failure(MyError.noUserConnected))
            return
        }

        let condition: [FirestoreCondition] = [.isEqualTo("join_code", code)]
        
        firebaseService.getDocuments(in: "lobby", whereFields: condition) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, !data.isEmpty, let lobbyId = data.first?["id"] as? String else {
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
        
        firebaseService.getDocument(in: "users", documentId: currentUserId) { data, error in
            if let error = error {
                completion(.failure(error))
            }
            else if let invites = data!["invites"] as? [String] {
                let newIvites = invites.filter { $0 != inviteId }
                self.firebaseService.updateDocument(in: "users", documentId: currentUserId, data: ["invites": newIvites]) { error in
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
        firebaseService.getDocument(in: "lobby", documentId: lobbyId) { data, error in
            if let error = error {
                completion(error)
            }
            guard let players = data?["players"] as? [String], let currentUserId = self.currentUserId else {
                completion(MyError.generalError)
                return
            }
            let updatedPlayers = players.filter { $0 != currentUserId }
            self.firebaseService.updateDocument(in: "lobby", documentId: lobbyId, data: ["players": updatedPlayers]) { error in
                completion(error)
            }
        }
    }
    
    
    func getLobbyData(lobbyId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard (firebaseService.currentUserID) != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        firebaseService.getDocument(in: "lobby", documentId: lobbyId) { lobbyData, error in
            if let error = error {
                completion(.failure(error))
            } else if let lobbyData = lobbyData, !lobbyData.isEmpty {
                completion(.success(lobbyData))
            } else {
                completion(.failure(MyError.noWaitingLobby))
            }
        }
    }
    
    
    //-----------------------------------------------------------------------------------
    //                                 GAME DATA
    //-----------------------------------------------------------------------------------
    
    func getCompletedGames(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseService.currentUserID else { completion(.failure(MyError.noUserConnected)); return }
        
        let conditions: [FirestoreCondition] = [.isEqualTo("status", "completed"), .arrayContains("players", currentUserId)]
        firebaseService.getDocuments(in: "games", whereFields: conditions) { gameData, error in
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
        
        firebaseService.getDocument(in: "games", documentId: gameId) { gameData, error in
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
    
    
    
    func saveStats(userAnswers: [String: UserAnswer], gameID: String, completion: @escaping (Result<Void, Error>) -> Void ) {
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
        
        let data: [String: Any] = ["user_answers.\(currentUserId)": answersData, "status": "completed"]
        
        firebaseService.updateDocument(in: "games", documentId: gameID, data: data) { error in
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
        let listener = firebaseService.addCollectionSnapshotListener(in: "games") { result in
            switch result {
            case .success(let documentsData):
                for data in documentsData {
                    if let players = data["players"] as? [String], let status = data["status"] as? String, status == "waiting", let gameId = data["id"] as? String, players.contains(self.firebaseService.currentUserID!) {
                        completion(.success(gameId))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return listener
    }
    
    func ListenForGameLaunch(completion: @escaping (Result<String, Error>) -> Void) -> ListenerRegistration  {
        let listener = firebaseService.addCollectionSnapshotListener(in: "games") { result in
            switch result {
            case .success(let documentsData):
                for data in documentsData {
                    if let players = data["players"] as? [String], let status = data["status"] as? String, status == "waiting", let gameId = data["id"] as? String, players.contains(self.firebaseService.currentUserID!) {
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

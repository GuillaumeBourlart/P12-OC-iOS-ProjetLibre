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
    
    private var firestoreService: FirestoreServiceProtocol
    private var firebaseAuthService: FirebaseAuthServiceProtocol
     var apiManager = OpenTriviaDatabaseManager(service: Service(networkRequest: AlamofireNetworkRequest()))
    
    init(firestoreService: FirestoreServiceProtocol = FirestoreService(),
         firebaseAuthService: FirebaseAuthServiceProtocol = FirebaseAuthService()) {
        self.firestoreService = firestoreService
        self.firebaseAuthService = firebaseAuthService
    }
    
    var difficulty: String?
    var category: Int?
    var currentLobbyId: String?
    
    
    
    private let db = Firestore.firestore() // Référence à Firestore
    var currentUserId: String? { return firebaseAuthService.currentUserID }
    // ID de l'utilisateur actuel
    
    
    //-----------------------------------------------------------------------------------
    //                                 GAME CREATION
    //-----------------------------------------------------------------------------------
    
    func searchCompetitiveLobby(completion: @escaping (Result<Void, Error>) -> Void ) {
        guard (firebaseAuthService.currentUserID) != nil else {
            completion(.failure(MyError.noUserConnected)); return
        }
        
        let conditions: [FirestoreCondition] = [.isEqualTo("status", "waiting"), .isEqualTo("competitive", true)]
        firestoreService.getDocuments(in: "lobby", whereFields: conditions) { lobbyData, error in
            if let error = error {
                completion(.failure(error))
            } else if let lobbyData = lobbyData, !lobbyData.isEmpty {
                print("Lobby trouvé")
                let lobbyId = lobbyData.first!["id"] as! String
                self.currentLobbyId = lobbyId
                self.joinCompetitiveLobby(lobbyId: lobbyId) { success in
                    switch success {
                    case .success():
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } else {
                print("Création d'un nouveau lobby")
                self.createCompetitiveLobby() { success in
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
    
    func createCompetitiveLobby(completion: @escaping (Result<Void, Error>) -> Void ) {
        guard let currentUserId = firebaseAuthService.currentUserID else {
            completion(.failure(MyError.noUserConnected)); return
        }
        
        let newLobby = db.collection("lobby").document()
        firestoreService.setData(in: "lobby", documentId: newLobby.documentID, data: ["id": newLobby.documentID, "creator": currentUserId, "competitive": true, "status": "waiting"]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Nouveau lobby créé avec l'ID: \(newLobby.documentID)")
                self.currentLobbyId = newLobby.documentID
                completion(.success(()))
            }
        }
    }
    
    func deleteCurrentLobby(completion: @escaping (Result<Void, Error>) -> Void ) {
        guard firebaseAuthService.currentUserID != nil else {
            completion(.failure(MyError.noUserConnected)); return
        }
        guard let lobbyId = currentLobbyId else {
            print("Aucun lobby actif")
            return
        }
        
        firestoreService.deleteDocument(in: "lobby", documentId: lobbyId) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.currentLobbyId = nil
                completion(.success(()))
            }
        }
        
        
    }
    
    func joinCompetitiveLobby(lobbyId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else {
            completion(.failure(MyError.noUserConnected)); return
        }

        firestoreService.updateDocument(in: "lobby", documentId: lobbyId, data: ["status": "matched"]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.firestoreService.getDocument(in: "lobby", documentId: lobbyId) { lobbyData, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let lobbyData = lobbyData else { return }
                let creator = lobbyData["creator"] as! String
                let players = [creator, currentUserId]
                
                self.createGame(competitive: true, players: players, creator: creator) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(_):
                        print("Game created successfully")
                        
                        self.deleteCurrentLobby() { result in
                            switch result {
                            case .failure(let error): completion(.failure(error))
                            case .success():print("Lobby deleted with ID: \(lobbyId)")
                                            completion(.success(()))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func createGame(competitive: Bool, players: [String], creator: String, completion: @escaping (Result<String, Error>) -> Void) {
        self.apiManager.fetchQuestions(inCategory: category, difficulty: difficulty) { result in
            switch result {
            case .failure(let error): print(error)
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
                    "creator": creator,
                    "status": "waiting",
                    "players": players,
                    "date": FieldValue.serverTimestamp(),
                    "competitive": competitive,
                    "questions": questionsDict
                ]
                
                self.firestoreService.setData(in: "games", documentId: gameId, data: gameData) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    completion(.success(gameId))
                    print("Game created with ID: \(gameId)")
                    
                }
            }
        }
    }
    
    func getQuestions(gameId: String, completion: @escaping (Result<[UniversalQuestion], Error>) -> Void) {
        guard firebaseAuthService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        firestoreService.getDocument(in: "games", documentId: gameId) { gameData, error in
            if let error = error {
                print("Error fetching document: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let gameData = gameData else {
                print("Failed to fetch game data or game does not exist")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch game data or game does not exist"])))
                return
            }
            
            print("Game data: \(gameData)")
            
            guard let questionsData = gameData["questions"] as? [String: [String: Any]] else {
                print("Failed to get questions or questions are not in the expected format")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get questions or questions are not in the expected format"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                var questions = [UniversalQuestion]()
                for (questionId, questionData) in questionsData {
                    let jsonData = try JSONSerialization.data(withJSONObject: questionData, options: [])
                    var question = try decoder.decode(UniversalQuestion.self, from: jsonData)
                    question.id = questionId
                    questions.append(question)
                }
                completion(.success(questions))
            } catch let error {
                print("Failed to decode questions: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    
    //-----------------------------------------------------------------------------------
    //                                 GAME DATA
    //-----------------------------------------------------------------------------------
    
    func getCompletedGames(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { completion(.failure(MyError.noUserConnected)); return }
        
        let conditions: [FirestoreCondition] = [.isEqualTo("status", "completed"), .arrayContains("players", currentUserId)]
        firestoreService.getDocuments(in: "games", whereFields: conditions) { gameData, error in
            if let error = error {
                completion(.failure(error))
            } else if let gameData = gameData, !gameData.isEmpty {
                var completedGames = [GameData]()
                for data in gameData {
                    do {
                        let convertedDataWithDate = self.convertTimestampsToDate(in: data)
                        let jsonData = try JSONSerialization.data(withJSONObject: convertedDataWithDate, options: [])
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let gameData = try decoder.decode(GameData.self, from: jsonData)
                        completedGames.append(gameData)
                    }  catch {
                        print("Error decoding: \(error)")
                        completion(.failure(error))
                    }
                }
                
                FirebaseUser.shared.History = completedGames
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch completed games"])))
            }
        }
    }
    
    func getGameData(gameId: String, completion: @escaping (Result<GameData, Error>) -> Void) {
        guard firebaseAuthService.currentUserID != nil else { completion(.failure(MyError.noUserConnected)); return }
        
        firestoreService.getDocument(in: "games", documentId: gameId) { gameData, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let gameData = gameData else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch game data"])))
                return
            }
            
            do {
                print("Game data: \(gameData)")
                
                let convertedDataWithDate = self.convertTimestampsToDate(in: gameData)
                let jsonData = try JSONSerialization.data(withJSONObject: convertedDataWithDate, options: [])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let gameData = try decoder.decode(GameData.self, from: jsonData)
                FirebaseUser.shared.History?.append(gameData)
                completion(.success(gameData))
            } catch {
                print("Error decoding game data: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    
    
    func saveStats(userAnswers: [String: UserAnswer], gameID: String, completion: @escaping (Result<Void, Error>) -> Void ) {
        guard let currentUserId = firebaseAuthService.currentUserID else {
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
        
        firestoreService.updateDocument(in: "games", documentId: gameID, data: data) { error in
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
    
    
    func listenForGameStart(completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { completion(.failure(MyError.noUserConnected)); return }
        
        let conditions: [FirestoreCondition] = [.arrayContains("players", currentUserId), .isEqualTo("status", "waiting")]
        firestoreService.getDocuments(in: "games", whereFields: conditions) { gameData, error in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(.failure(error))
            } else if let gameData = gameData, !gameData.isEmpty {
                for data in gameData {
                    if let gameId = data["id"] as? String {
                        print("Game started with ID: \(gameId)")
                        completion(.success(gameId))
                        return
                    }
                }
            } else {
                print("Aucun document ne répond aux critères de la requête")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Aucun document ne répond aux critères de la requête"])))
            }
        }
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

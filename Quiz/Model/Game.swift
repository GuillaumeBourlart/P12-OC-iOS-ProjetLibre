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
    private var apiManager = OpenTriviaDatabaseManager(service: Service(networkRequest: AlamofireNetworkRequest()))
    
    init(firestoreService: FirestoreServiceProtocol = FirestoreService(),
         firebaseAuthService: FirebaseAuthServiceProtocol = FirebaseAuthService()) {
        self.firestoreService = firestoreService
        self.firebaseAuthService = firebaseAuthService
    }
  
    var difficulty: String?
    var category: Int?
    var currentLobbyId: String?
    
    
    
    private let db = Firestore.firestore() // Référence à Firestore
    private var currentUserId: String? { return Auth.auth().currentUser?.uid }
    // ID de l'utilisateur actuel
    
    
    //-----------------------------------------------------------------------------------
    //                                 GAME CREATION
    //-----------------------------------------------------------------------------------
    
    func searchCompetitiveLobby(completion: @escaping (Result<Void, Error>) -> Void ) {
        guard (firebaseAuthService.currentUserID) != nil else {
            print("Aucun utilisateur connecté")
            return
        }
        
        let conditions: [FirestoreCondition] = [.isEqualTo("status", "waiting"), .isEqualTo("competitive", true)]
        firestoreService.getDocuments(in: "lobby", whereFields: conditions) { querySnapshot, error in
            // Continuez comme dans votre implémentation initiale
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = querySnapshot, !snapshot.isEmpty {
                    // Un lobby disponible a été trouvé
                    print("Lobby trouvé")
                    let lobbyId = snapshot.documents.first!.documentID
                    self.currentLobbyId = lobbyId
                    self.joinCompetitiveLobby(lobbyId: lobbyId) {success in
                        switch success {
                        case .success():
                            completion(.success(()))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    // Aucun lobby disponible, en créer un nouveau
                    print("Création d'un nouveau lobby")
                    self.createCompetitiveLobby() {success in
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
                print("Aucun utilisateur connecté");
                return
            }
            
            let newLobby = db.collection("lobby").document()
            firestoreService.setData(in: "lobby", documentId: newLobby.documentID, data: ["creator": currentUserId, "competitive": true, "status": "waiting"]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    print("Nouveau lobby créé avec l'ID: \(newLobby.documentID)")
                    self.currentLobbyId = newLobby.documentID
                    completion(.success(()))
                }
            }
        }

        func cancelSearch(completion: @escaping (Result<Void, Error>) -> Void ) {
            guard firebaseAuthService.currentUserID != nil else {
                print("Aucun utilisateur connecté");
                return
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
                print("Aucun utilisateur connecté")
                return
            }
            
            // Update lobby status to "matched"
            firestoreService.updateDocument(in: "lobby", documentId: lobbyId, data: ["status": "matched"]) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // API call to fetch quiz questions
                self.apiManager.fetchQuestions(inCategory: nil, difficulty: nil) { result in
                    switch result {
                    case .success(let questions):
                        // Create new game in "games" collection
                        let gameId = UUID().uuidString
                        
                        // Convertir les questions en un dictionnaire avec des identifiants uniques
                        var questionsDict = [String: [String: Any]]()
                        for var question in questions {
                            question.id = UUID().uuidString
                            questionsDict[question.id!] = question.dictionary
                        }
                        
                        let gameData: [String: Any] = [
                            "name": "Quizz entre amis",
                            "status": "waiting",
                            "players": [currentUserId],
                            "date": FieldValue.serverTimestamp(),
                            "competitive": true,
                            "questions": [String: [String: Any]]()
                        ]

                        
                        
                        
                        
                        self.firestoreService.setData(in: "games", documentId: gameId, data: gameData) { error in
                            if let error = error {
                                completion(.failure(error))
                                return
                            }
                            
                            print("Game created with ID: \(gameId)")
                            
                            // Delete the lobby from "lobby" collection
                            self.firestoreService.deleteDocument(in: "lobby", documentId: lobbyId) { error in
                                if let error = error {
                                    completion(.failure(error))
                                    return
                                }
                                
                                print("Lobby deleted with ID: \(lobbyId)")
                                completion(.success(()))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch quiz questions: \(error.localizedDescription)"])))
                    }
                }
            }
        }
    
    func getQuestions(gameId: String, completion: @escaping (Result<[UniversalQuestion], Error>) -> Void) {
        guard firebaseAuthService.currentUserID != nil else { print("Aucun utilisateur connecté"); return}
        
            firestoreService.getDocument(in: "games", documentId: gameId) { (snapshot, error) in
            
            if let error = error {
                print("Error fetching document: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists,
                  let gameData = snapshot.data() else {
                print("Failed to fetch game data or game does not exist")
                completion(.failure(NSError (domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch game data or game does not exist"])))
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
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        _ = db.collection("games")
        let conditions: [FirestoreCondition] = [.isEqualTo("status", "completed"), .arrayContains("players", currentUserId)]
        firestoreService.getDocuments(in: "games", whereFields: conditions) { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let snapshot = querySnapshot {
                    var completedGames = [GameData]()
                    for document in snapshot.documents {
                        do {
                            let snapshotData = document.data()
                            print("before conversion \(snapshotData)")
                            let convertedDataWithDate = self.convertTimestampsToDate(in: snapshotData)
                            print("converted \(convertedDataWithDate)")
                            let jsonData = try JSONSerialization.data(withJSONObject: convertedDataWithDate, options: [])
                            let decoder = JSONDecoder()
                            decoder.dateDecodingStrategy = .iso8601
                            print(jsonData)
                            var gameData = try decoder.decode(GameData.self, from: jsonData)
                            gameData.id = document.documentID
                            completedGames.append(gameData)
                        }  catch {
                            print("Error decoding: \(error)")
                            if let decodingError = error as? DecodingError {
                                print(decodingError)
                            }
                            completion(.failure(error))
                            return
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
        
        
        firestoreService.getDocument(in: "games", documentId: gameId) { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot,
                  snapshot.exists,
                  let snapshotData = snapshot.data() else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch game data"])))
                return
            }
            
            do {
                print("le snapchot: \(String(describing: snapshot.data()))" )
                
                let convertedDataWithDate = self.convertTimestampsToDate(in: snapshotData)
                let jsonData = try JSONSerialization.data(withJSONObject: convertedDataWithDate, options: [])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601// Decode Date from a Unix timestamp
                let gameData = try decoder.decode(GameData.self, from: jsonData)
                FirebaseUser.shared.History?.append(gameData)
                completion(.success(gameData))
            } catch {
                print("erreur snapshot")
                completion(.failure(error))
            }
        }
    }
    
    
    
    func saveStats(userAnswers: [String: UserAnswer], gameID: String, completion: @escaping (Result<Void, Error>) -> Void ) {
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        
        
        var answersData: [String: Any] = [:]
        for (key, userAnswer) in userAnswers {
            answersData[key] = userAnswer.dictionary
        }
        
        let data: [String: Any] = ["user_answers.\(currentUserId)": answersData, "status": "completed"]
        
        firestoreService.updateDocument(in: "games", documentId: gameID, data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                let data: [String: Any] = ["games": FieldValue.arrayUnion([gameID])]
                self.firestoreService.updateDocument(in: "users", documentId: currentUserId, data: data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        FirebaseUser.shared.userInfo?.games.append(gameID)
                        completion(.success(()))
                    }
                }
            }
        }
    }
    //-----------------------------------------------------------------------------------
    //                                 LISTENER FOR GAME STARTING
    //-----------------------------------------------------------------------------------
    
    
    func listenForGameStart(completion: @escaping (Bool, String?) -> Void) {
        guard let currentUserId = firebaseAuthService.currentUserID else { print("Aucun utilisateur connecté"); return}
        
        let conditions: [FirestoreCondition] = [.arrayContains("players", currentUserId), .isEqualTo("status", "waiting")]
        firestoreService.getDocuments(in: "games", whereFields: conditions) { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else if let snapshot = querySnapshot, !snapshot.isEmpty {
                    for document in snapshot.documents {
                        let gameId = document.documentID
                        print("Game started with ID: \(gameId)")
                        completion(true, gameId)
                    }
                } else {
                    print("Aucun document ne répond aux critères de la requête")
                    completion(false, nil)
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

//
//  GameProperty.swift
//  Copyright © 2025 keizukky. All rights reserved.
//

import SwiftUI

// MARK: - Data Models
struct SudokuPuzzle: Codable, Identifiable {
    let id: Int
    let name: String
    let puzzle: [[Int]]
    let solution: [[Int]]
}

struct GameState: Codable {
    var userNumbers: [[Int]]
    var userMemos: [[[Int]]]
    var isCompleted: Bool
    var playTime: TimeInterval
    var history: [GameAction]
    var redoStack: [GameAction]
    
    init() {
        userNumbers = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        userMemos = Array(repeating: Array(repeating: [], count: 9), count: 9)
        isCompleted = false
        playTime = 0
        history = []
        redoStack = []
    }
}

struct GameAction: Codable {
    enum ActionType: Codable {
        case numberInput(row: Int, col: Int, oldNumber: Int, newNumber: Int)
        case memoInput(row: Int, col: Int, oldMemos: [Int], newMemos: [Int])
        case delete(row: Int, col: Int, oldNumber: Int, oldMemos: [Int])
    }
    
    let type: ActionType
    let timestamp: Date
}

// MARK: - Game Manager
class GameManager: ObservableObject {
    @Published var puzzles: [SudokuPuzzle] = []
    @Published var gameStates: [Int: GameState] = [:]
    @Published var completedPuzzles: Set<Int> = []
    
    init() {
        loadPuzzles()
        loadGameStates()
    }
    
    private func loadPuzzles() {
        // ダミーデータ
        puzzles = [
            SudokuPuzzle(id: 1, name: "パズル 1",
                puzzle: [
                    [5,3,0,0,7,0,0,0,0],
                    [6,0,0,1,9,5,0,0,0],
                    [0,9,8,0,0,0,0,6,0],
                    [8,0,0,0,6,0,0,0,3],
                    [4,0,0,8,0,3,0,0,1],
                    [7,0,0,0,2,0,0,0,6],
                    [0,6,0,0,0,0,2,8,0],
                    [0,0,0,4,1,9,0,0,5],
                    [0,0,0,0,8,0,0,7,9]
                ],
                solution: [
                    [5,3,4,6,7,8,9,1,2],
                    [6,7,2,1,9,5,3,4,8],
                    [1,9,8,3,4,2,5,6,7],
                    [8,5,9,7,6,1,4,2,3],
                    [4,2,6,8,5,3,7,9,1],
                    [7,1,3,9,2,4,8,5,6],
                    [9,6,1,5,3,7,2,8,4],
                    [2,8,7,4,1,9,6,3,5],
                    [3,4,5,2,8,6,1,7,9]
                ]
            ),
            SudokuPuzzle(id: 2, name: "パズル 2",
                puzzle: [
                    [0,2,0,6,0,8,0,0,0],
                    [5,8,0,0,0,9,7,0,0],
                    [0,0,0,0,4,0,0,0,0],
                    [3,7,0,0,0,0,5,0,0],
                    [6,0,0,0,0,0,0,0,4],
                    [0,0,8,0,0,0,0,1,3],
                    [0,0,0,0,2,0,0,0,0],
                    [0,0,9,8,0,0,0,3,6],
                    [0,0,0,3,0,6,0,9,0]
                ],
                solution: [
                    [1,2,3,6,7,8,9,4,5],
                    [5,8,4,2,3,9,7,6,1],
                    [9,6,7,1,4,5,3,2,8],
                    [3,7,2,4,6,1,5,8,9],
                    [6,9,1,5,8,3,2,7,4],
                    [4,5,8,7,9,2,6,1,3],
                    [8,3,6,9,2,4,1,5,7],
                    [2,1,9,8,5,7,4,3,6],
                    [7,4,5,3,1,6,8,9,2]
                ]
            )
        ]
        
        // 残り8問分のダミーデータを追加
        for i in 3...10 {
            puzzles.append(
                SudokuPuzzle(id: i, name: "パズル \(i)",
                    puzzle: generateRandomPuzzle(),
                    solution: generateRandomSolution()
                )
            )
        }
    }
    
    private func generateRandomPuzzle() -> [[Int]] {
        // 簡単なダミーパズル生成
        var puzzle = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        let positions = [(0,0,5), (0,1,3), (1,4,7), (2,2,8), (3,6,4), (4,4,5), (5,1,7), (6,7,2), (7,3,9), (8,8,1)]
        for (row, col, num) in positions {
            puzzle[row][col] = num
        }
        return puzzle
    }
    
    private func generateRandomSolution() -> [[Int]] {
        // 簡単なダミー解答
        return [
            [5,3,4,6,7,8,9,1,2],
            [6,7,2,1,9,5,3,4,8],
            [1,9,8,3,4,2,5,6,7],
            [8,5,9,7,6,1,4,2,3],
            [4,2,6,8,5,3,7,9,1],
            [7,1,3,9,2,4,8,5,6],
            [9,6,1,5,3,7,2,8,4],
            [2,8,7,4,1,9,6,3,5],
            [3,4,5,2,8,6,1,7,9]
        ]
    }
    
    func getGameState(for puzzleId: Int) -> GameState {
        return gameStates[puzzleId] ?? GameState()
    }
    
    func saveGameState(_ state: GameState, for puzzleId: Int) {
        gameStates[puzzleId] = state
        if state.isCompleted {
            completedPuzzles.insert(puzzleId)
        }
        saveGameStates()
    }
    
    private func saveGameStates() {
        if let data = try? JSONEncoder().encode(gameStates) {
            UserDefaults.standard.set(data, forKey: "gameStates")
        }
        let completedArray = Array(completedPuzzles)
        UserDefaults.standard.set(completedArray, forKey: "completedPuzzles")
    }
    
    private func loadGameStates() {
        if let data = UserDefaults.standard.data(forKey: "gameStates"),
           let states = try? JSONDecoder().decode([Int: GameState].self, from: data) {
            gameStates = states
        }
        
        if let completed = UserDefaults.standard.array(forKey: "completedPuzzles") as? [Int] {
            completedPuzzles = Set(completed)
        }
    }
}

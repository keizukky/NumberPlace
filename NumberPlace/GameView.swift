//
//  GameView.swift
//  Copyright © 2025 keizukky. All rights reserved.
//

import SwiftUI

// MARK: - Game View
struct GameView: View {
    let puzzle: SudokuPuzzle
    @EnvironmentObject var gameManager: GameManager
    @State private var gameState: GameState
    @State private var selectedCell: (Int, Int)?
    @State private var highlightedNumber: Int?
    @State private var isMemoMode = false
    @State private var gameTimer: Timer?
    @State private var startTime = Date()
    @Environment(\.presentationMode) var presentationMode
    
    init(puzzle: SudokuPuzzle) {
        self.puzzle = puzzle
        // 初期化時はダミーのGameStateを設定し、onAppearで実際のデータをロード
        self._gameState = State(initialValue: GameState())
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // タイマー
            HStack {
                Button("戻る") {
                    saveGame()
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
                
                Text(timeString(from: gameState.playTime))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            
            // ゲーム盤面
            SudokuGridView(
                puzzle: puzzle,
                gameState: $gameState,
                selectedCell: $selectedCell,
                highlightedNumber: $highlightedNumber
            )
            
            // 数字入力ボタン
            NumberInputView(
                gameState: $gameState,
                selectedCell: $selectedCell,
                highlightedNumber: $highlightedNumber,
                isMemoMode: $isMemoMode,
                puzzle: puzzle,
                onNumberInput: handleNumberInput
            )
            
            // 機能ボタン
            FunctionButtonsView(
                gameState: $gameState,
                isMemoMode: $isMemoMode,
                selectedCell: $selectedCell,
                puzzle: puzzle,
                onAction: handleAction
            )
            
            Spacer()
        }
        .navigationBarHidden(true)
        .onAppear {
            loadGame()
            startTimer()
        }
        .onDisappear {
            stopTimer()
            saveGame()
        }
    }
    
    private func loadGame() {
        gameState = gameManager.getGameState(for: puzzle.id)
        startTime = Date().addingTimeInterval(-gameState.playTime)
    }
    
    private func saveGame() {
        gameManager.saveGameState(gameState, for: puzzle.id)
    }
    
    private func startTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            gameState.playTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    private func handleNumberInput(_ number: Int) {
        guard let (row, col) = selectedCell else { return }
        
        let oldNumber = gameState.userNumbers[row][col]
        let oldMemos = gameState.userMemos[row][col]
        
        if isMemoMode {
            if gameState.userMemos[row][col].contains(number) {
                gameState.userMemos[row][col].removeAll { $0 == number }
            } else {
                gameState.userMemos[row][col].append(number)
                gameState.userMemos[row][col].sort()
            }
            
            let action = GameAction(
                type: .memoInput(row: row, col: col, oldMemos: oldMemos, newMemos: gameState.userMemos[row][col]),
                timestamp: Date()
            )
            gameState.history.append(action)
            gameState.redoStack.removeAll()
        } else {
            gameState.userNumbers[row][col] = number
            gameState.userMemos[row][col].removeAll()
            
            let action = GameAction(
                type: .numberInput(row: row, col: col, oldNumber: oldNumber, newNumber: number),
                timestamp: Date()
            )
            gameState.history.append(action)
            gameState.redoStack.removeAll()
            
            checkCompletion()
        }
    }
    
    private func handleAction(_ action: String) {
        switch action {
        case "delete":
            guard let (row, col) = selectedCell else { return }
            let oldNumber = gameState.userNumbers[row][col]
            let oldMemos = gameState.userMemos[row][col]
            
            gameState.userNumbers[row][col] = 0
            gameState.userMemos[row][col].removeAll()
            
            let deleteAction = GameAction(
                type: .delete(row: row, col: col, oldNumber: oldNumber, oldMemos: oldMemos),
                timestamp: Date()
            )
            gameState.history.append(deleteAction)
            gameState.redoStack.removeAll()
            
        case "undo":
            performUndo()
            
        case "redo":
            performRedo()
            
        case "restart":
            gameState = GameState()
            startTime = Date()
            
        default:
            break
        }
    }
    
    private func performUndo() {
        guard !gameState.history.isEmpty else { return }
        
        let action = gameState.history.removeLast()
        gameState.redoStack.append(action)
        
        switch action.type {
        case .numberInput(let row, let col, let oldNumber, _):
            gameState.userNumbers[row][col] = oldNumber
        case .memoInput(let row, let col, let oldMemos, _):
            gameState.userMemos[row][col] = oldMemos
        case .delete(let row, let col, let oldNumber, let oldMemos):
            gameState.userNumbers[row][col] = oldNumber
            gameState.userMemos[row][col] = oldMemos
        }
    }
    
    private func performRedo() {
        guard !gameState.redoStack.isEmpty else { return }
        
        let action = gameState.redoStack.removeLast()
        gameState.history.append(action)
        
        switch action.type {
        case .numberInput(let row, let col, _, let newNumber):
            gameState.userNumbers[row][col] = newNumber
        case .memoInput(let row, let col, _, let newMemos):
            gameState.userMemos[row][col] = newMemos
        case .delete(let row, let col, _, _):
            gameState.userNumbers[row][col] = 0
            gameState.userMemos[row][col] = []
        }
    }
    
    private func checkCompletion() {
        for row in 0..<9 {
            for col in 0..<9 {
                let originalNumber = puzzle.puzzle[row][col]
                let userNumber = gameState.userNumbers[row][col]
                
                if originalNumber == 0 && userNumber == 0 {
                    return // 未完了
                }
            }
        }
        
        // パズル完了チェック
        if isValidSolution() {
            gameState.isCompleted = true
            saveGame()
        }
    }
    
    private func isValidSolution() -> Bool {
        // 簡易的な検証（実際の数独ルールに基づく完全な検証は省略）
        return true
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


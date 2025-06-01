//
//  NumberPlaceApp.swift
//  Copyright © 2025 keizukky. All rights reserved.
//
import SwiftUI
import Foundation

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

// MARK: - Main App
@main
struct SudokuApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var gameManager = GameManager()
    
    var body: some View {
        NavigationView {
            PuzzleListView()
        }
        .environmentObject(gameManager)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Puzzle List View
struct PuzzleListView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        List {
            ForEach(gameManager.puzzles) { puzzle in
                NavigationLink(destination: GameView(puzzle: puzzle)) {
                    HStack {
                        Text(puzzle.name)
                            .font(.headline)
                        
                        Spacer()
                        
                        if gameManager.completedPuzzles.contains(puzzle.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("数独パズル")
    }
}

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

// MARK: - Sudoku Grid View
struct SudokuGridView: View {
    let puzzle: SudokuPuzzle
    @Binding var gameState: GameState
    @Binding var selectedCell: (Int, Int)?
    @Binding var highlightedNumber: Int?
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<9, id: \.self) { col in
                        CellView(
                            row: row,
                            col: col,
                            puzzle: puzzle,
                            gameState: gameState,
                            isSelected: selectedCell?.0 == row && selectedCell?.1 == col,
                            isHighlighted: shouldHighlight(row: row, col: col),
                            onTap: {
                                if selectedCell?.0 == row && selectedCell?.1 == col {
                                    selectedCell = nil
                                    highlightedNumber = nil
                                } else {
                                    selectedCell = (row, col)
                                    let number = getCurrentNumber(row: row, col: col)
                                    highlightedNumber = number > 0 ? number : nil
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.black)
    }
    
    private func shouldHighlight(row: Int, col: Int) -> Bool {
        guard let highlightNum = highlightedNumber else { return false }
        let currentNum = getCurrentNumber(row: row, col: col)
        return currentNum == highlightNum
    }
    
    private func getCurrentNumber(row: Int, col: Int) -> Int {
        if puzzle.puzzle[row][col] != 0 {
            return puzzle.puzzle[row][col]
        }
        return gameState.userNumbers[row][col]
    }
}

// MARK: - Cell View
struct CellView: View {
    let row: Int
    let col: Int
    let puzzle: SudokuPuzzle
    let gameState: GameState
    let isSelected: Bool
    let isHighlighted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .border(Color.black, width: borderWidth)
                
                if let number = displayNumber {
                    Text("\(number)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(numberColor)
                } else if !memos.isEmpty {
                    VStack(spacing: 1) {
                        ForEach(0..<3, id: \.self) { memoRow in
                            HStack(spacing: 1) {
                                ForEach(0..<3, id: \.self) { memoCol in
                                    let memoNumber = memoRow * 3 + memoCol + 1
                                    Text(memos.contains(memoNumber) ? "\(memoNumber)" : "")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 35, height: 35)
        .disabled(false)
    }
    
    private var displayNumber: Int? {
        if puzzle.puzzle[row][col] != 0 {
            return puzzle.puzzle[row][col]
        }
        let userNumber = gameState.userNumbers[row][col]
        return userNumber > 0 ? userNumber : nil
    }
    
    private var memos: [Int] {
        return gameState.userMemos[row][col]
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue.opacity(0.3)
        } else if isHighlighted {
            return .yellow.opacity(0.3)
        } else {
            return .white
        }
    }
    
    private var numberColor: Color {
        return puzzle.puzzle[row][col] != 0 ? .black : .orange
    }
    
    private var borderWidth: CGFloat {
        let isThickVertical = (col == 2 || col == 5)
        let isThickHorizontal = (row == 2 || row == 5)
        return (isThickVertical || isThickHorizontal) ? 2 : 1
    }
}

// MARK: - Number Input View
struct NumberInputView: View {
    @Binding var gameState: GameState
    @Binding var selectedCell: (Int, Int)?
    @Binding var highlightedNumber: Int?
    @Binding var isMemoMode: Bool
    let puzzle: SudokuPuzzle
    let onNumberInput: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { number in
                    NumberButton(
                        number: number,
                        isEnabled: isNumberEnabled(number),
                        onTap: { onNumberInput(number) }
                    )
                }
            }
            
            HStack(spacing: 8) {
                ForEach(6...9, id: \.self) { number in
                    NumberButton(
                        number: number,
                        isEnabled: isNumberEnabled(number),
                        onTap: { onNumberInput(number) }
                    )
                }
            }
        }
    }
    
    private func isNumberEnabled(_ number: Int) -> Bool {
        guard selectedCell != nil else { return false }
        
        // 盤面に同じ数字が9個ある場合は無効
        var count = 0
        for row in 0..<9 {
            for col in 0..<9 {
                if puzzle.puzzle[row][col] == number || gameState.userNumbers[row][col] == number {
                    count += 1
                }
            }
        }
        return count < 9
    }
}

// MARK: - Number Button
struct NumberButton: View {
    let number: Int
    let isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("\(number)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isEnabled ? .black : .gray)
                .frame(width: 50, height: 50)
                .background(isEnabled ? Color.blue.opacity(0.2) : Color.white)
                .border(Color.gray, width: 1)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Function Buttons View
struct FunctionButtonsView: View {
    @Binding var gameState: GameState
    @Binding var isMemoMode: Bool
    @Binding var selectedCell: (Int, Int)?
    let puzzle: SudokuPuzzle
    let onAction: (String) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                FunctionButton(
                    title: isMemoMode ? "メモON" : "メモOFF",
                    backgroundColor: isMemoMode ? .green : .gray,
                    onTap: { isMemoMode.toggle() }
                )
                
                FunctionButton(
                    title: "戻す",
                    backgroundColor: .orange,
                    isEnabled: !gameState.history.isEmpty,
                    onTap: { onAction("undo") }
                )
                
                FunctionButton(
                    title: "進む",
                    backgroundColor: .orange,
                    isEnabled: !gameState.redoStack.isEmpty,
                    onTap: { onAction("redo") }
                )
            }
            
            HStack(spacing: 12) {
                FunctionButton(
                    title: "削除",
                    backgroundColor: .red,
                    isEnabled: selectedCell != nil,
                    onTap: { onAction("delete") }
                )
                
                FunctionButton(
                    title: "リセット",
                    backgroundColor: .purple,
                    onTap: { onAction("restart") }
                )
            }
        }
    }
}

// MARK: - Function Button
struct FunctionButton: View {
    let title: String
    let backgroundColor: Color
    let isEnabled: Bool
    let onTap: () -> Void
    
    init(title: String, backgroundColor: Color, isEnabled: Bool = true, onTap: @escaping () -> Void) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.isEnabled = isEnabled
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 60, height: 35)
                .background(isEnabled ? backgroundColor : backgroundColor.opacity(0.3))
                .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}

//
//  NumberPlaceApp.swift
//  Copyright © 2025 keizukky. All rights reserved.
//

// SudokuApp.swift
import SwiftUI

@main
struct SudokuApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Models
struct SudokuProblem: Codable, Identifiable {
    let id: Int
    let problem: [[Int]]
    let solution: [[Int]]
}

// ViewModel
class SudokuViewModel: ObservableObject {
    @Published var problems: [SudokuProblem] = []
    @Published var completedIds: Set<Int> = []

    init() {
        loadProblems()
        loadProgress()
    }

    func loadProblems() {
        if let url = Bundle.main.url(forResource: "sudoku_problems", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let loaded = try? JSONDecoder().decode([SudokuProblem].self, from: data) {
            self.problems = loaded
        }
    }

    func loadProgress() {
        if let saved = UserDefaults.standard.array(forKey: "completedIds") as? [Int] {
            completedIds = Set(saved)
        }
    }

    func saveProgress() {
        UserDefaults.standard.set(Array(completedIds), forKey: "completedIds")
    }
}

// ContentView (Top Screen)
struct ContentView: View {
    @StateObject var viewModel = SudokuViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.problems) { problem in
                NavigationLink(destination: PlayView(problem: problem, viewModel: viewModel)) {
                    HStack {
                        Text("Problem #\(problem.id)")
                        Spacer()
                        if viewModel.completedIds.contains(problem.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Sudoku List")
        }
    }
}

// PlayView (Play Screen)
struct PlayView: View {
    let problem: SudokuProblem
    @ObservedObject var viewModel: SudokuViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var board: [[Int]]
    @State private var notes: [[[Bool]]]
    @State private var selectedRow: Int? = nil
    @State private var selectedCol: Int? = nil
    @State private var isNoteMode = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var elapsedTime = 0

    init(problem: SudokuProblem, viewModel: SudokuViewModel) {
        self.problem = problem
        self.viewModel = viewModel
        let savedKey = "board_\(problem.id)"
        if let savedData = UserDefaults.standard.data(forKey: savedKey),
           let savedBoard = try? JSONDecoder().decode([[Int]].self, from: savedData) {
            _board = State(initialValue: savedBoard)
        } else {
            _board = State(initialValue: problem.problem)
        }
        let notesInit = Array(repeating: Array(repeating: Array(repeating: false, count: 9), count: 9), count: 9)
        _notes = State(initialValue: notesInit)
    }

    var body: some View {
        VStack {
            // Timer
            Text("Time: \(elapsedTime) sec")
                .padding()

            // Board
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 4), count: 9), spacing: 4) {
                ForEach(0..<9, id: \.self) { row in
                    ForEach(0..<9, id: \.self) { col in
                        let value = board[row][col]
                        ZStack {
                            Rectangle()
                                .stroke(Color.gray, lineWidth: 1)
                                .background((selectedRow == row && selectedCol == col) ? Color.yellow.opacity(0.3) : Color.white)
                            if value != 0 {
                                Text("\(value)")
                                    .foregroundColor(problem.problem[row][col] != 0 ? .black : .orange)
                            } else if let selected = selectedRow, let selectedC = selectedCol, notes[row][col].contains(true) {
                                VStack {
                                    ForEach(0..<3) { i in
                                        HStack {
                                            ForEach(0..<3) { j in
                                                let num = i * 3 + j
                                                Text(notes[row][col][num] ? "\(num+1)" : "")
                                                    .font(.caption2)
                                                    .frame(width: 12, height: 12)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: 40, height: 40)
                        .onTapGesture {
                            selectedRow = row
                            selectedCol = col
                        }
                    }
                }
            }
            .padding()

            // Number buttons
            VStack {
                ForEach(0..<2) { row in
                    HStack {
                        ForEach(1 + row*5..<min(10, 6 + row*5)) { num in
                            Button(action: {
                                inputNumber(num)
                            }) {
                                Text("\(num)")
                                    .frame(width: 40, height: 40)
                                    .background(Color.orange.opacity(boardContains(num) ? 0.2 : 1.0))
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                            }
                            .disabled(boardContains(num))
                        }
                    }
                }
            }
            .padding(.vertical)

            // Function buttons
            HStack {
                Button("Note: \(isNoteMode ? "ON" : "OFF")") {
                    isNoteMode.toggle()
                }
                Button("Undo") { } // Implement undo stack if needed
                Button("Redo") { } // Implement redo stack if needed
                Button("Delete") {
                    if let r = selectedRow, let c = selectedCol {
                        board[r][c] = 0
                    }
                }
                Button("Restart") {
                    board = problem.problem
                }
            }
            .padding()

            Button("Back") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onReceive(timer) { _ in
            elapsedTime += 1
        }
        .onDisappear {
            saveBoard()
        }
    }

    func inputNumber(_ num: Int) {
        guard let r = selectedRow, let c = selectedCol else { return }
        guard problem.problem[r][c] == 0 else { return }

        if isNoteMode {
            notes[r][c][num - 1].toggle()
        } else {
            board[r][c] = num
            if board == problem.solution {
                viewModel.completedIds.insert(problem.id)
                viewModel.saveProgress()
            }
        }
    }

    func boardContains(_ num: Int) -> Bool {
        board.joined().filter { $0 == num }.count >= 9
    }

    func saveBoard() {
        if let data = try? JSONEncoder().encode(board) {
            let key = "board_\(problem.id)"
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

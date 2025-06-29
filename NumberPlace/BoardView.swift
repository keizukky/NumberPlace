//
//  BoardView.swift
//  Copyright © 2025 keizukky. All rights reserved.
//

import SwiftUI

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

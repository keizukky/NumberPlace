//
//  NumberButton.swift
//  Copyright © 2025 keizukky. All rights reserved.
//

import SwiftUI

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

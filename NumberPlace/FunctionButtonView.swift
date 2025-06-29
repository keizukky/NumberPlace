//
//  FunctionButtonView.swift
//  Copyright © 2025 keizukky. All rights reserved.
//

import SwiftUI

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


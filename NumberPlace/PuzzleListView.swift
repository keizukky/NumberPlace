//
//  PuzzleListView.swift
//  Copyright © 2025 keizukky. All rights reserved.
//

import SwiftUI

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

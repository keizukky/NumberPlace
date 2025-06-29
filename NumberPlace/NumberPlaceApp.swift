//
//  NumberPlaceApp.swift
//  Copyright © 2025 keizukky. All rights reserved.
//
import SwiftUI

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

//
//  timer.swift
//  stirnraten
//
//  Created by Leah Marie Lövenich on 07.08.26.
//

import SwiftUI
import Combine

struct TimerView: View {
    let selectedCategory: Category // Nimmt die gewählte Kategorie entgegen
    @State private var timeRemaining = 3 // 1 Minute in Sekunden
    @State private var isFinished = false
    
    // Timer initialisieren, der jede Sekunde feuert
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Full-screen background color
                //selectedCategory.color
                //    .frame(maxWidth: .infinity, maxHeight: .infinity)
                //    .ignoresSafeArea()
                
                // 2. Your content on top
                VStack(spacing: 30) {
                    Text("Get Ready!")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(timeString(from: timeRemaining))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .contentTransition(.numericText())
                    
                    Text(selectedCategory.title)
                        .font(.largeTitle)
                }
                .padding()
                .background(selectedCategory.color)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding()

            // Empfange das Timer-Signal jede Sekunde
            .onReceive(timer) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    isFinished = true
                }
            }

            // Navigation zur neuen View, sobald der Timer abgelaufen ist
            .navigationDestination(isPresented: $isFinished) {
                GameView(selectedCategory: selectedCategory)
            }
        }
        .navigationBarBackButtonHidden(false) // Verhindert Zurückgehen, falls nicht gewünscht
    }
    
    // Hilfsfunktion zur Formatierung der Sekunden in MM:SS
    private func timeString(from totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

//
//  timer.swift
//  stirnraten
//
//  Created by Leah Marie Lövenich on 07.08.26.
//

import SwiftUI
import Combine

struct TimerView: View {
    let selectedCategory: Category
    @State private var contrastingColor: Color = .black
    @State private var timeRemaining = 3 //sekunden
    @State private var isFinished = false
    
    @State private var backgroundColor: Color? = nil
    
    // Timer initialisieren, der jede Sekunde feuert
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        selectedCategory.color.opacity(1)
            .ignoresSafeArea()
            .overlay {
                NavigationStack {
                    ZStack {
                        VStack(spacing: 30) {
                            Text("Get Ready!")
                                .font(.headline)
                                .foregroundStyle(contrastingColor.opacity(0.7))
                            
                            Text(timeString(from: timeRemaining))
                                .font(.system(size: 60, weight: .bold, design: .monospaced))
                                .contentTransition(.numericText())
                                .foregroundStyle(contrastingColor)
                            
                            Text(selectedCategory.title)
                                .font(.largeTitle)
                                .foregroundStyle(contrastingColor)
                        }
                        .padding()
                    }
                    .padding()
                    
                    .onAppear() {
                        contrastingColor = selectedCategory.color.contrastingTextColor()
                    }
                    
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
                .navigationBarBackButtonHidden(true) // Verhindert Zurückgehen, falls nicht gewünscht
            }
    }
    
    // Hilfsfunktion zur Formatierung der Sekunden in MM:SS
    private func timeString(from totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

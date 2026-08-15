//
//  GameView.swift
//  stirnraten
//
//  Created by Leah Marie Lövenich on 05.08.26.
//

// GameView.swift
import SwiftUI
import Combine
import CoreMotion

struct GameView: View {
    let selectedCategory: Category // Nimmt die gewählte Kategorie entgegen
    @State private var timeRemaining = 60 // 1 Minute in Sekunden
    @State private var isFinished = false
    
    // word to display
    @State private var currentWord = ""
    
    // Timer initialisieren, der jede Sekunde feuert
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Schwellenwert für das Kippen (ca. 25-30 Grad Neigung)
    private let tiltThreshold: Double = 0.69
    @State private var motionManager = CMMotionManager()
    @State private var isTiltCoolingDown = false
    @State private var lastTilt: Double = 0
    @State private var startTilt: Double = 0
    @State private var firstMeasure: Bool = true
    
    // usedwords and which were skipped and correct
    @State public var usedWords: [String] = []
    @State public var correctIndices: [Int] = []
    
    @State private var feedbackType: FeedbackType? = nil
    
    enum FeedbackType {
        case correct
        case incorrect
    }
    
    @State private var flashColor: Color? = nil
    
    var body: some View {
        selectedCategory.color.opacity(0.5)
            .ignoresSafeArea()
            .overlay {
                NavigationStack {
                    ZStack {
                        // 2. Your content on top
                        VStack(spacing: 30) {
                            Text("Verbleibende Zeit")
                                .font(.headline)
                            
                            Text(timeString(from: timeRemaining))
                                .font(.system(size: 60, weight: .bold, design: .monospaced))
                                .contentTransition(.numericText())
                            
                            Text(currentWord)
                                .font(.largeTitle)
                        }
                        .padding()
                        .foregroundStyle(selectedCategory.color.contrastingTextColor())
                        .background(selectedCategory.color)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        if let flashColor = flashColor {
                            flashColor
                                .ignoresSafeArea()
                        }
                    }
                    .padding()
                    .onAppear() {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        if (currentWord.isEmpty) {
                            randomWord()
                        }
                        startTiltDetection()
                    }
                    // Empfange das Timer-Signal jede Sekunde
                    .onReceive(timer) { _ in
                        if timeRemaining > 0 {
                            timeRemaining -= 1
                        } else {
                            isFinished = true
                        }
                    }
                    .onDisappear() {
                        stopTiltDetection()
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    }
                    // Navigation zur neuen View, sobald der Timer abgelaufen ist
                    .navigationDestination(isPresented: $isFinished) {
                        EndView(
                            usedWords: usedWords,
                            correctIndices: correctIndices,
                            onRepeat: restartGame
                        )
                    }
                }
                .navigationBarBackButtonHidden(false) // Verhindert Zurückgehen, falls nicht gewünscht
            }
        
    }
    
    
    private func restartGame() {
        timeRemaining = 60
        currentWord = ""
        usedWords = []
        correctIndices = []
        flashColor = nil
        isTiltCoolingDown = false
        firstMeasure = true
    }

    // Hilfsfunktion zur Formatierung der Sekunden in MM:SS
    private func timeString(from totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Hilfsfunktion die ein random Wort holt
    private func randomWord() {
        let available = selectedCategory.terms.filter { !usedWords.contains($0) }
        guard let word = available.randomElement() else {
            // z. B. Runde beenden, usedWords zurücksetzen, oder ähnliches
            return
        }
        currentWord = word
        usedWords.append(word)
    }
    
    private func startTiltDetection() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else { return }
            
            if (firstMeasure) {
                firstMeasure = false
                startTilt = motion.attitude.roll
            }
            
            let roll = motion.attitude.roll
            let tilt = roll - startTilt

            // Nach einer Antwort bleibt das Ergebnis sichtbar, bis das Gerät
            // wieder in seine Ausgangsposition gebracht wurde.
            if isTiltCoolingDown {
                if abs(tilt) < tiltThreshold * 0.35 {
                    finishTilt()
                }
                return
            }

            if tilt > tiltThreshold {
                handleSuccess()
                print("Nach rechts gekippt")
                correctIndices.append(0)
                handleTilt()
            } else if tilt < -tiltThreshold {
                handleFailure()
                print("Nach links gekippt")
                correctIndices.append(1)
                handleTilt()
            }
        }
    }
    
    private func stopTiltDetection() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func handleTilt() {
        isTiltCoolingDown = true
    }

    private func finishTilt() {
        flashColor = nil
        randomWord()
        isTiltCoolingDown = false
    }
    
    private func handleSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Das Ergebnis bleibt sichtbar, bis das Gerät wieder gerade gehalten wird.
        flashColor = .green
    }

    private func handleFailure() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        // Das Ergebnis bleibt sichtbar, bis das Gerät wieder gerade gehalten wird.
        flashColor = .red
    }
}

// Die Ziel-View, die nach 1 Minute erscheint
struct EndView: View {
    let usedWords: [String]
    let correctIndices: [Int]
    let onRepeat: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var countCorrect = 0
    @State private var countAll = 0
    
    var body: some View {
        VStack {
            Text("Zeit abgelaufen!")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            Text("\(countCorrect) / \(countAll) Wörter richtig!")
            
            List(Array(usedWords.enumerated()), id: \.offset) { index, word in
                HStack {
                    Text(word)
                        .font(.body)
                    
                    Spacer()
                    
                    // Display status based on tilt direction/index
                    if correctIndices.indices.contains(index) {
                        Image(systemName: correctIndices[index] == 1 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(correctIndices[index] == 1 ? .green : .red)
                    }
                }
            }
            .listStyle(.plain) // Optional: changes the visual style of the list

            Button {
                onRepeat()
                dismiss()
            } label: {
                Label("Runde wiederholen", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear() {
            countCorrectWords()
            countAll = usedWords.count
        }
        .navigationBarBackButtonHidden(false) // Verhindert Zurückgehen, falls nicht gewünscht
    }
    
    private func countCorrectWords() {
        correctIndices.forEach { entry in
            if (entry == 1) {
                countCorrect += 1
            }
        }
        print(correctIndices)
    }
}



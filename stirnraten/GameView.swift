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
                        EndView(usedWords: usedWords, correctIndices: correctIndices)            }
                }
                .navigationBarBackButtonHidden(false) // Verhindert Zurückgehen, falls nicht gewünscht
            }
        
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
            
            // 2. Ignore motion updates if we're currently in a cooldown period
            guard !isTiltCoolingDown else { return }
            
            let roll = motion.attitude.roll
            print("roll", roll)
            print("first", startTilt)
            
            if roll > (startTilt+tiltThreshold) {
                handleSuccess()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                print("Nach rechts gekippt")
                correctIndices.append(0)
                handleTilt()
            } else if roll < (startTilt-tiltThreshold) {
                handleFailure()
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                print("Nach links gekippt")
                correctIndices.append(1)
                handleTilt()
            }
        }
    }
    
    private func stopTiltDetection() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    // 3. Centralized tilt handler with a non-blocking delay
    private func handleTilt() {
        isTiltCoolingDown = true

        Task {
            // Erst das Feedback vollständig anzeigen und danach den Begriff wechseln.
            try? await Task.sleep(for: .seconds(0.9))
            randomWord()

            // Die gesamte Sperrzeit bleibt bei einer Sekunde.
            try? await Task.sleep(for: .seconds(0.1))
            isTiltCoolingDown = false
        }
    }
    
    private func handleSuccess() {
        // haptisches feedback für player
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // animation for explainer
        withAnimation(.easeIn(duration: 0.1)) {
            flashColor = Color.green
        }
        
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.easeOut(duration: 0.3)) {
                flashColor = nil
            }
        }
    }
    
    private func handleFailure() {
        // haptisches feedback für player
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        
        // animation for explainer
        withAnimation(.easeIn(duration: 0.1)) {
            flashColor = Color.red
        }
        
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.easeOut(duration: 0.3)) {
                flashColor = nil
            }
        }
    }
}

// Die Ziel-View, die nach 1 Minute erscheint
struct EndView: View {
    let usedWords: [String]
    let correctIndices: [Int]
    
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



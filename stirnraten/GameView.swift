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
    let selectedCategory: Category
    @State private var timeRemaining = 90 // in Sekunden
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
    @State private var backgroundColor: Color? = nil
    
    @State private var goToMainMenu = false
    
    var body: some View {
        backgroundColor
            .ignoresSafeArea()
            .overlay {
                NavigationStack {
                    ZStack {
                        // 2. Your content on top
                        VStack(spacing: 30) {
                            Text("Verbleibende Zeit")
                                .font(.headline)
                                .foregroundStyle(selectedCategory.color.contrastingTextColor())
                            
                            Text(timeString(from: timeRemaining))
                                .font(.system(size: 60, weight: .bold, design: .monospaced))
                                .contentTransition(.numericText())
                                .foregroundStyle(selectedCategory.color.contrastingTextColor())
                            
                            Text(currentWord)
                                .font(.largeTitle)
                                .foregroundStyle(selectedCategory.color.contrastingTextColor())
                        }
                        .padding()
                        
                        if let flashColor = flashColor {
                            flashColor
                                .ignoresSafeArea()
                        }
                    }
                    .onAppear() {
                        backgroundColor = selectedCategory.color.opacity(1)
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
                    
                    // navigate to the next view
                    .navigationDestination(isPresented: $isFinished) {
                        EndView(selectedCategory: selectedCategory, usedWords: usedWords, correctIndices: correctIndices)
                    }
                    .navigationDestination(isPresented: $goToMainMenu) {
                        LandscapeDashboardView()
                    }
                    
                    .toolbar {
                        // go back to home menu
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                goToMainMenu = true
                            } label: {
                                Image(systemName: "house.fill")
                                    .foregroundStyle(selectedCategory.color.contrastingTextColor())
                            }
                        }
                        // display category
                        ToolbarItem(placement: .principal) {
                            Text(selectedCategory.title)
                                .font(.headline)
                                .foregroundStyle(selectedCategory.color.contrastingTextColor())
                        }
                        // pause button
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                
                            } label: {
                                Image(systemName: "pause.fill")
                                    .foregroundStyle(selectedCategory.color.contrastingTextColor())
                            }
                        }
                    }
                }
                .navigationBarBackButtonHidden(true)
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
                handleFailure()
                print("Nach rechts gekippt")
                correctIndices.append(0)
                handleTilt()
            } else if roll < (startTilt-tiltThreshold) {
                handleSuccess()
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
        randomWord()
        
        // Wait 1 second on a background Task, then reset the flag
        Task {
            try? await Task.sleep(for: .seconds(1))
            isTiltCoolingDown = false
        }
    }
    
    private func handleSuccess() {
        // haptisches feedback für player
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // animation for explainer
        withAnimation(.easeIn(duration: 0.2)) {
            flashColor = Color.green
        }
        
        Task {
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeOut(duration: 0.2)) {
                flashColor = nil
            }
        }
    }
    
    private func handleFailure() {
        // haptisches feedback für player
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        
        // animation for explainer
        withAnimation(.easeIn(duration: 0.2)) {
            flashColor = Color.red
        }
        
        Task {
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeOut(duration: 0.2)) {
                flashColor = nil
            }
        }
    }
}

struct EndView: View {
    let selectedCategory: Category
    let usedWords: [String]
    let correctIndices: [Int]
    
    @State private var countCorrect = 0
    @State private var countAll = 0
    
    @State private var isFinished = false
    @State private var goToMainMenu = false
    @State private var repeatGame = false
    
    @State private var backgroundColor: Color? = nil
    
    var body: some View {
        backgroundColor
            .ignoresSafeArea()
            .overlay {
                ZStack {
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
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                    .onAppear() {
                        countCorrectWords()
                        countAll = usedWords.count
                        backgroundColor = selectedCategory.color
                    }
                    .navigationBarBackButtonHidden(false)
                }
                // navigate to the next view
                .navigationDestination(isPresented: $isFinished) {
                    EndView(selectedCategory: selectedCategory, usedWords: usedWords, correctIndices: correctIndices)
                }
                .navigationDestination(isPresented: $goToMainMenu) {
                    LandscapeDashboardView()
                }
                .navigationDestination(isPresented: $repeatGame) {
                    TimerView(selectedCategory: selectedCategory)
                }
                
                .toolbar {
                    // go to main menu
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            goToMainMenu = true
                        } label: {
                            Image(systemName: "house.fill")
                                .foregroundStyle(selectedCategory.color.contrastingTextColor())
                        }
                    }
                    // display category
                    ToolbarItem(placement: .principal) {
                        Text(selectedCategory.title)
                            .font(.headline)
                            .foregroundStyle(selectedCategory.color.contrastingTextColor())
                    }
                    // repeat with the same category
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            repeatGame = true
                        } label: {
                            Image(systemName: "repeat")
                                .foregroundStyle(selectedCategory.color.contrastingTextColor())
                        }
                    }
                }
                .navigationBarBackButtonHidden(true)
            }
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

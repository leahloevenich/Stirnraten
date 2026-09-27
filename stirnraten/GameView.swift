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
    let selectedCategory: [Category]
    let randomCatForDisplay: Int
    
    @State private var currentCat = 0
    @State private var timerTime = 90 // in Sekunden
    @State private var timeRemaining = 90
    @State private var timePassed = 0
    @State private var isFinished = false
    
    // word to display
    @State private var currentWord = ""
    
    // Timer initialisieren, der jede Sekunde feuert
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var isBreakActive: Bool = false
    
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
                                .foregroundStyle(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
                            
                            Text(timeString(from: timeRemaining))
                                .font(.system(size: 60, weight: .bold, design: .monospaced))
                                .contentTransition(.numericText())
                                .foregroundStyle(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
                            
                            Text(currentWord)
                                .font(.largeTitle)
                                .foregroundStyle(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
                        }
                        .padding()
                        
                        if let flashColor = flashColor {
                            flashColor
                                .ignoresSafeArea()
                        }
                    }
                    .onAppear() {
                        backgroundColor = selectedCategory[randomCatForDisplay].color.opacity(1)
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        if (currentWord.isEmpty) {
                            randomWord()
                        }
                        startTiltDetection()
                    }
                    // Empfange das Timer-Signal jede Sekunde
                    .onReceive(timer) { _ in
                        if (!isBreakActive) {
                            timeRemaining = timerTime - timePassed
                            if timeRemaining > 0 {
                                timePassed += 1
                            } else {
                                isFinished = true
                            }
                        }
                    }
                    .onDisappear() {
                        stopTiltDetection()
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    }
                    
                    // navigate to the next view
                    .navigationDestination(isPresented: $isFinished) {
                        EndView(selectedCategory: selectedCategory, randomCatForDisplay: randomCatForDisplay, usedWords: usedWords, correctIndices: correctIndices)
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
                                    .foregroundStyle(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
                            }
                        }
                        // display category
                        ToolbarItem(placement: .principal) {
                            Text(selectedCategory[currentCat].title)
                                .font(.headline)
                                .foregroundStyle(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
                        }
                        // pause button
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                isBreakActive = true
                            } label: {
                                Image(systemName: "pause.fill")
                                    .foregroundStyle(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
                            }
                        }
                    }
                    .fullScreenCover(isPresented: $isBreakActive) {
                        ZStack {
                            Color.black.opacity(0.4).ignoresSafeArea()
                            
                            VStack(spacing: 20) {
                                Text("! Spiel pausiert !")
                                    .font(.headline)
                                Text("Das Spiel wurde pausiert. Drücke 'Fortsetzen' um fortzufahren.")
                                    .multilineTextAlignment(.center)
                                
                                Button("Fortsetzen") {
                                    isBreakActive = false
                                }
                                .padding()
                                .background(selectedCategory[randomCatForDisplay].color)
                                .foregroundColor(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
                                .cornerRadius(8)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(50)
                            .padding(40)
                        }
                        .background(selectedCategory[randomCatForDisplay].color.opacity(1)) // Optional: removes default opaque sheet background if needed
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
        // first, get random Category
        currentCat = Int.random(in: 0...selectedCategory.count - 1)
        
        // then, choose word
        let available = selectedCategory[currentCat].terms.filter { !usedWords.contains($0) }
        guard let word = available.randomElement() else {
            // neues word ziehen
            randomWord()
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

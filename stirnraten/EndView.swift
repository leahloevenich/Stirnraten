//
//  EndView.swift
//  stirnraten
//
//  Created by Leah Marie Lövenich on 27.09.26.
//
import SwiftUI

struct EndView: View {
    let selectedCategory: [Category]
    let randomCatForDisplay: Int
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
                            .foregroundStyle(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
                        Text("\(countCorrect) / \(countAll) Wörter richtig!")
                            .foregroundStyle(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
                        
                        List(Array(usedWords.enumerated()), id: \.offset) { index, word in
                            HStack {
                                Text(word)
                                    .font(.body)
                                    .foregroundStyle(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
                                
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
                        backgroundColor = selectedCategory[randomCatForDisplay].color
                    }
                    .navigationBarBackButtonHidden(false)
                }
                // navigate to the next view
                .navigationDestination(isPresented: $isFinished) {
                    EndView(selectedCategory: selectedCategory, randomCatForDisplay: randomCatForDisplay, usedWords: usedWords, correctIndices: correctIndices)
                }
                .navigationDestination(isPresented: $goToMainMenu) {
                    LandscapeDashboardView()
                }
                .navigationDestination(isPresented: $repeatGame) {
                    TimerView(selectedCategory: selectedCategory, randomCatForDisplay: Int.random(in: 0..<selectedCategory.count))
                }
                
                .toolbar {
                    // go to main menu
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
                        Text((selectedCategory.count > 1) ? "Multiselect" : selectedCategory[0].title)
                            .font(.headline)
                            .foregroundStyle(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
                    }
                    // repeat with the same category
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            repeatGame = true
                        } label: {
                            Image(systemName: "repeat")
                                .foregroundStyle(selectedCategory[randomCatForDisplay].color.contrastingTextColor())
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

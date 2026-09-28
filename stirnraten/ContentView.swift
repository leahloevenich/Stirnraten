//
//  ContentView.swift
//  stirnraten
//
//  Created by Leah Marie Lövenich on 05.08.26.
//

import SwiftUI

// Ein zweispaltiges Dashboard/Layout speziell für das Querformat (Landscape)
struct LandscapeDashboardView: View {
    // Auslesen der vertikalen Größenklasse:
    // .compact = meist Querformat auf iPhones
    // .regular = Hochformat auf iPhones oder iPads
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let categories = CategoryManager.shared.categories
    @State private var isMultiselectActive: Bool = false
    @State private var selectedCategory: [Category] = []
    @State private var randomCatForDisplay: Int = 0
    
    @State private var navigateToTimer: Bool = false
    @State private var showingAlert: Bool = false
    
    // just for fun
    @State private var showConfetti = false

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                NavigationStack{
                    VStack(spacing: 12) {
                        // Scrollbare Kategorien über den restlichen Bildschirm
                        ScrollView(.vertical, showsIndicators: true) {
                            // Adaptive Spalten: Passt so viele Karten wie möglich nebeneinander
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                                ForEach(categories) { category in
                                    if (isMultiselectActive) {
                                        Button {
                                            if (selectedCategory.contains(where: { $0 == category })) {
                                                // deselect
                                                selectedCategory.removeAll(where: { $0 == category })
                                            } else {
                                                // select
                                                selectedCategory.append(category)
                                            }
                                        } label: {
                                            CatCard(title: category.title, color: ((selectedCategory.contains(where: { $0 == category })) ? category.color.opacity(0.5) : category.color))
                                                .transition(.scale)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        // no multiselect: choose one and start instant
                                        Button {
                                            selectedCategory.removeAll()
                                            selectedCategory.append(category)
                                            startGame()
                                        } label: {
                                            CatCard(title: category.title, color: category.color)
                                                .transition(.scale)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                        .scrollEdgeEffectHidden(true, for: .top)   // removes the blur/fade under the toolbar
                    }
                    .overlay {
                        if showConfetti {
                            ConfettiView()
                        }
                    }
                    .toolbar {
                        // multiselect buttons
                        ToolbarItemGroup(placement: .topBarLeading) {
                            // multiselect on and off
                            Button {
                                isMultiselectActive.toggle()
                                selectedCategory.removeAll()
                            } label: {
                                Label(
                                    isMultiselectActive ? "Multiselect ON" : "Multiselect OFF",
                                    systemImage: isMultiselectActive ? "square.grid.2x2.fill" : "square.grid.2x2"
                                )
                                .labelStyle(.iconOnly)
                            }
                            
                            if (isMultiselectActive) {
                                // select all and deselect all
                                Button {
                                    if (selectedCategory.isEmpty) {
                                        // select all
                                        selectedCategory = categories
                                    } else {
                                        // deselect all
                                        selectedCategory.removeAll()
                                    }
                                } label: {
                                    Label(
                                        selectedCategory.isEmpty ? "Select All" : "Deselect All",
                                        systemImage:
                                            selectedCategory.isEmpty ? "checkmark.square.fill" : "checkmark.square")
                                }
                                .labelStyle(.iconOnly)

                                // start game
                                Button {
                                    // Action for third button
                                    startGame()
                                } label: {
                                    Label("Start Game", systemImage: "play.circle.fill")
                                }
                                .labelStyle(.iconOnly)
                            }
                        }
                        // keine ahnung was ich daraus machen soll
                        ToolbarItem(placement: .topBarTrailing) {
                            // 2. Custom Toggle Button
                            Button {
                                addRandomCat()
                                if (!isMultiselectActive) {
                                    startGame()
                                }
                            } label: {
                                Label(
                                    "Random",
                                    systemImage: "shuffle"
                                )
                                .labelStyle(.iconOnly)
                            }
                        }
                        ToolbarItem(placement: .principal) {
                            Button {
                                showConfetti = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) { showConfetti = false }
                            } label: {
                                Text("Wähle eine Kategorie")
                                    .font(.title)
                                    .bold()
                                    .padding(.horizontal, 10)
                            }
                            .buttonStyle(.glass)
                        }
                        .sharedBackgroundVisibility(.hidden)
                    }
                    
                    .alert(isPresented: $showingAlert) {
                        Alert(
                            title: Text("! STOP !"),
                            message: Text("Wähle mindestens eine Kategorie!"),
                            dismissButton: .default(Text("Return"))
                        )
                    }
                    .navigationDestination(isPresented: $navigateToTimer) {
                        TimerView(
                            selectedCategory: selectedCategory,
                            randomCatForDisplay: randomCatForDisplay
                        )
                    }
                }
                .navigationBarBackButtonHidden(true)
            } else {
                // ==========================================
                // HOCHFORMAT-LAYOUT (Fallback)
                // ==========================================
                VStack(spacing: 20) {
                    Image(systemName: "rotate.right")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Bitte drehe dein Gerät ins Querformat, um das vollständige Dashboard zu sehen.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

        }

    }
    
    // Hilfsfunktion zum Starten des Games
    private func startGame() {
        if (selectedCategory.count == 0) {
            showingAlert = true
        } else {
            randomCatForDisplay = (Int.random(in: 0..<selectedCategory.count))
            navigateToTimer = true
        }
    }
    
    // Hilfsfunktion zum Starten des Games mit random category
    private func addRandomCat() {
        if (selectedCategory.count == categories.count) {return}
        
        let available = categories.filter { !selectedCategory.contains($0) }
        guard let catToAdd = available.randomElement() else {
            return
        }
        selectedCategory.append(catToAdd)
    }
}

extension Color {   //entgegengesetze Farbe Text->Hintergrund
    func contrastingTextColor() -> Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.6 ? .black : .white
    }
}

// Wiederverwendbare Karte für Kennzahlen
struct CatCard: View {
    let title: String   // kat name
    let color: Color    // background color
    //let describtion: String //if needed
    
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(color.contrastingTextColor())
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
        .background(color)
        .cornerRadius(12)
    }
}

#Preview {
    LandscapeDashboardView()
}

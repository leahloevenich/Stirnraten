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

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                NavigationStack{
                    VStack(spacing: 12) {
                        // Titel obenzentriert
                        Text("Wähle eine Kategorie aus")
                            .font(.title2)
                            .bold()
                            .padding(.top, 8)
                        
                        // Scrollbare Kategorien über den restlichen Bildschirm
                        ScrollView(.vertical, showsIndicators: true) {
                            // Adaptive Spalten: Passt so viele Karten wie möglich nebeneinander
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                                ForEach(categories) { category in
                                    NavigationLink(destination: TimerView(selectedCategory: category)) {
                                        CatCard(title: category.title, color: category.color)
                                            .transition(.scale)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
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
                .foregroundColor(.secondary)
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

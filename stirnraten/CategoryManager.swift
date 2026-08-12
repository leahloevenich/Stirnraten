//
//  CategoryManager.swift
//  stirnraten
//
//  Created by Leah Marie Lövenich on 05.08.26.
//

import SwiftUI

// 1. Das Datenmodell (Codable macht das Parsen von JSON extrem einfach)
struct Category: Identifiable, Codable {
    let id: String
    let title: String
    let colorHex: String
    let terms: [String] // Die Begriffe zum Erraten
    
    // Wandelt den Hex-Code aus der JSON in eine SwiftUI-Farbe um
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// 2. Hilfsklasse zum Laden der statischen Datei
class CategoryManager {
    static let shared = CategoryManager()
    
    let categories: [Category]
    
    private init() {
        // Lädt die Datei 'Categories.json' direkt aus dem App Bundle
        if let url = Bundle.main.url(forResource: "Categories", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Category].self, from: data) {
            self.categories = decoded
        } else {
            print("⚠️ Fehler: 'Categories.json' konnte nicht geladen werden.")
            self.categories = []
        }
    }
}

// 3. Kleine Erweiterung für Hex-Farben in SwiftUI
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

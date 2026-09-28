//
//  Colors.swift
//  stirnraten
//
//  Created by Leah Marie Lövenich on 28.09.26.
//

import SwiftUI

extension Color {
    static let appBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? .black : .white
    })
}

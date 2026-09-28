//
//  Confetti.swift
//  stirnraten
//
//  Created by Leah Marie Lövenich on 28.09.26.
//

import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat = .random(in: 0...1)          // horizontal start (fraction of width)
    let drift: CGFloat = .random(in: -60...60)   // sideways movement
    let color: Color = [.red, .orange, .yellow, .green, .blue, .purple, .pink].randomElement()!
    let size: CGFloat = .random(in: 6...12)
    let duration: Double = .random(in: 1.8...3.2)
    let delay: Double = .random(in: 0...0.5)
    let rotation: Double = .random(in: 360...1080)
}

struct ConfettiView: View {
    @State private var fall = false
    private let pieces = (0..<80).map { _ in ConfettiPiece() }

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { p in
                Rectangle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size * 1.5)
                    .rotationEffect(.degrees(fall ? p.rotation : 0))
                    .position(
                        x: p.x * geo.size.width + (fall ? p.drift : 0),
                        y: fall ? geo.size.height + 40 : -40
                    )
                    .animation(.easeIn(duration: p.duration).delay(p.delay), value: fall)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)   // taps go through to the buttons underneath
        .onAppear { fall = true }
    }
}

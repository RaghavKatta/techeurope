//
//  Badge.swift
//  HappyGut
//
//  Created by Samuele Viganò on 24/05/25.
//

import SwiftUI

struct Badge: View {
    var number: Int
    
    var badgeColor: Color {
        let progress = Double(number) / 100.0
        switch progress {
        case 0..<0.5:
            // Red to Yellow
            return .red
        case 0.5..<0.7:
            return .orange
        default:
            return .green
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(badgeColor)

            Text("\(number)")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                
            CircleLabelView(text: "Gut Score →")
                .foregroundStyle(badgeColor)
            
        }
       
    }
}


import SwiftUI

struct CircleLabelView: View {
    var text: String

    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let adjustedRadius = radius + 10
            ZStack {
                ForEach(Array(text.enumerated()), id: \.offset) { index, letter in
                    // Map characters along the bottom half (180° to 360°)
                    let angle = Angle.degrees(Double(index) / Double(text.count - 1) * -80 + 150)
                    
                    Text(String(letter))
                        .font(.system(size: 18, weight: .bold))
                        .rotationEffect(angle + .degrees(-90))
                        .position(
                            x: geometry.size.width / 2 + adjustedRadius * cos(CGFloat(angle.radians)),
                            y: geometry.size.height / 2 + adjustedRadius * sin(CGFloat(angle.radians))
                        )
                }
            }
        }
    }
}


#Preview {
    VStack(spacing: 20) {
        Badge(number: 10)
            .frame(height: 120)

        Badge(number: 50)
        Badge(number: 90)
    }
}

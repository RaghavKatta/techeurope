//
//  Untitled.swift
//  HappyGut
//
//  Created by Samuele Viganò on 24/05/25.
//



import SwiftUI

struct GutScoreView: View {
    // Variables
    let score = 83
    let inflammationTitle = "Inflammation threshold"
    let inflammationStatus = "Poor"
    let inflammationPercent = 80
    let inflammationDescription = "Avoid eating more inflammatory foods with today to decrease the likelyhood of pain and discomfort"

    let diversityTitle = "Microbiome diversity"
    let diversityStatus = "Great"
    let diversityValue = 94
    let diversityUnit = "pp"
    let diversityDescription = "pp refers to millions of bacterial species. It’s an estimate for the diversity. A more diverse biome can withstand more inflammation—is more resilient etc etc"

    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Score Circle
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 120, height: 120)
                Text("\(score)")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Gut Score")
                .font(.system(size: 32, weight: .black))

            // Inflammation Section
            VStack(alignment: .leading, spacing: 12) {
                Text(inflammationTitle)
                    .font(.title3.bold())
                Text(inflammationStatus)
                    .foregroundColor(.orange)
                    .bold()
                ProgressView(value: Double(inflammationPercent), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                Text("\(inflammationPercent)%")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(inflammationDescription)
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
            .padding()
            .background(Color(UIColor.systemYellow).opacity(0.2))
            .cornerRadius(20)

            // Microbiome Section
            VStack(alignment: .leading, spacing: 12) {
                Text(diversityTitle)
                    .font(.title3.bold())
                Text(diversityStatus)
                    .foregroundColor(.green)
                    .bold()
                ProgressView(value: Double(diversityValue), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                HStack {
                    Spacer()
                    Text("\(diversityValue)\(diversityUnit)")
                        .bold()
                }
                Text(diversityDescription)
                    .font(.subheadline)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(20)

            Spacer()

            // Close Button
            Button("Close") {
                dismiss()
            }
            .font(.title2.bold())
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .clipShape(Capsule())
        }
        .padding()
    }
}

#Preview {
    Rectangle()
        .sheet(isPresented: .constant(true)) {
            GutScoreView()
        }
}

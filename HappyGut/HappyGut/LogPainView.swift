//
//  LogPainView.swift
//  HappyGut
//
//  Created by Samuele Viganò on 24/05/25.
//



import SwiftUI



struct LogPainView: View {
    @State private var painValue: Double = 0
    let maxPain: Double = 10
    
    @Environment(\.dismiss) private var dismiss
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient Fill Proportional to Pain Level
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.size.height * (1 - painValue / maxPain))
                    LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]),
                                   startPoint: .top,
                                   endPoint: .bottom)
                        .frame(height: geometry.size.height * (painValue / maxPain))
                }
                .edgesIgnoringSafeArea(.all)

                VStack {
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                        .padding()
                        .overlay {
                            VStack {
                                // Title
                                Text("Log Pain")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                // Instruction
                                Text("Slide up to log how much pain you're feeling")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    //.padding(.bottom, 40)
                                
                                // Value
                                Text("\(Int(painValue))")
                                    .font(.system(size: 80, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding()
                        }
                        .frame(height: 200)
                    
                    
                    Spacer()
                    
                    // Drag Area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: geometry.size.height * 0.5)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let maxY = geometry.size.height * 0.5
                                    let clampedY = min(max(0, maxY - value.location.y), maxY)
                                    let newPain = (clampedY / maxY) * maxPain
                                    painValue = newPain
                                }
                        )
                }
                .padding()
                
                VStack {
                    Spacer()
                    
                    Button(action: {
                       dismiss()
                    }) {
                        Text("Confirm")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: 160)
                            .background(Color.black)
                            .cornerRadius(35)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 60)
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LogPainView()
}

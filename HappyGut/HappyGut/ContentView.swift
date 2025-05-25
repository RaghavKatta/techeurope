//
//  ContentView.swift
//  HappyGut
//
//  Created by Samuele Viganò on 24/05/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var model = Model()
    
    var body: some View {
        ZStack {
            ZStack {
                switch model.currentView {
                case .home:
                    TodayView(model: model) // Placeholder for HomeView
                case .groceries:
                    KartView()
                }
                
                
            }
            .overlay(alignment: .top) {
                topShader()
            }
            .overlay(alignment: .top) {
                topBar()
                    .frame(height: 100)
                    .padding()
            }
            .sheet(isPresented: $model.showGutScoreView) {
                GutScoreView()
            }
            .sheet(isPresented: $model.showLogPain) {
                LogPainView()
            }
            .sheet(isPresented: $model.showLogFood) {
                CameraView()
            }
            
            
            
            // MARK: --- Add View
            
            if model.showAddView {
                Rectangle()
                    .foregroundStyle(.thinMaterial)
                    //.transition(.blurReplace)
                    .ignoresSafeArea()
                
            }
            
        }
        .overlay(alignment: .bottom) {
            VStack {
                Spacer()
                TabBar(model: model)
                    .overlay(alignment: .topTrailing) {
                        if model.showAddView {
                            VStack(spacing: 20) {
                                Button {
                                    model.showLogPain.toggle()
                                    model.showAddView = false
                                } label: {
                                    Capsule()
                                        .foregroundStyle(.ultraThickMaterial)
                                        .frame(width: 170, height: 60)
                                        .overlay {
                                            Text("😖 Log pain")
                                                .bold()
                                        }
                                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 5)
                                }
                                
                                Button {
                                    model.showLogFood.toggle()
                                    model.showAddView = false
                                } label: {
                                    Capsule()
                                        .foregroundStyle(.ultraThickMaterial)
                                        .frame(width: 170, height: 60)
                                        .overlay {
                                            Text("🥗 Log Food")
                                                .bold()
                                        }
                                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 5)
                                }
                            }
                            .transition(.blurReplace.combined(with: .slide))
                            .padding(.top, -190)
                            .padding(.horizontal, 30)
                            
                        }
                    }
                
            }
            .ignoresSafeArea()
        }
        
    }
}


extension ContentView {
    @ViewBuilder func topShader() -> some View {
        Rectangle()
            .frame(height: 200)
            .foregroundStyle(
                .linearGradient(
                    colors: [.clear, .white, .white],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .ignoresSafeArea()
    }
    
    
    @ViewBuilder func topBar() -> some View {
        HStack {
            VStack {
                Text("Happy Gut")
                    .font(.title)
                    .bold()
                
                Spacer()
            }
            
            Spacer()
            
            VStack {
                Badge(number: model.gutScore)
                    .frame(width: model.isScrollingViewAtDefaultPosition ? 100 : 40)
                    .onTapGesture {
                        model.showGutScoreView.toggle()
                    }
                    .contentTransition(.numericText())
                Spacer()
            }
        }
    }
}




#Preview {
    ContentView()
}

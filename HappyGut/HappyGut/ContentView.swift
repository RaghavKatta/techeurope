//
//  ContentView.swift
//  HappyGut
//
//  Created by Samuele Viganò on 24/05/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var model = Model()
    @State var selectedFood: Food? = nil
    @Namespace var namespace
    var body: some View {
        ZStack {
            ZStack {
                switch model.currentView {
                case .home:
                    TodayView(model: model, namespace: namespace) // Placeholder for HomeView
                        
                case .groceries:
                    KartView(model: model) // Placeholder for KartView)
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
                CameraView(model: model)
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
      //  .disabled(model.selectedFood != nil)
        //.brightness(model.selectedFood != nil ? -10 : 0)
        
        .overlay {
          
                ZStack {
                    if let _ = model.selectedFood {
                        Rectangle()
                            .ignoresSafeArea()
                            .foregroundStyle(.black.opacity(0.5))
                            .onTapGesture {
                                if model.selectedFood != nil {
                                    withAnimation(.smooth(duration: 0.3)) {
                                        model.selectedFood = nil
                                    }
                                }
                            }
                    }
                    
                    VStack {
                        Spacer()
//                        
//                        RoundedRectangle(cornerRadius: 25)
//                            .frame(height: 500)
//                            .overlay {
                                if let selectedFood = model.selectedFood {
                                    FoodRecap(food: selectedFood, namespace: namespace)
                                        .transition(.offset(y: 600))
                                }
                         
//                            }
                        
                        //  .transition(.slide)
                    }
                    .ignoresSafeArea()
                    //.offset(y: model.selectedFood != nil ? 0 : 1100)
                }
            
            
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
            VStack(alignment: .leading) {
                if model.isScrollingViewAtDefaultPosition {
                    Text("Happy Gut")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Text(model.currentView.title(view: model.currentView))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .contentTransition(.numericText())
                
                Spacer()
            }
            
            Spacer()
            
            VStack {
                Badge(showText: $model.isScrollingViewAtDefaultPosition, number: model.gutScore)
                    .frame(width: model.isScrollingViewAtDefaultPosition ? 100 : 50)
                    .onTapGesture {
                        model.showGutScoreView.toggle()
                    }
                    .contentTransition(.numericText())
                    .offset(y: model.isScrollingViewAtDefaultPosition ? 0 : -20)
                
                Spacer()
            }
        }
    }
}




#Preview {
    ContentView()
}

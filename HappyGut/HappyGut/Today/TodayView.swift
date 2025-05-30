//
//  TodayView.swift
//  HappyGut
//
//  Created by Samuele Viganò on 24/05/25.
//
import SwiftUI

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollOffsetModifier: ViewModifier {
    let coordinateSpace: String
    var onChange: (CGFloat) -> Void

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named(coordinateSpace)).minY)
                }
            )
            .onPreferenceChange(ScrollOffsetKey.self, perform: onChange)
    }
}

extension View {
    func onScrollOffsetChange(coordinateSpace: String = "scroll", perform: @escaping (CGFloat) -> Void) -> some View {
        self.modifier(ScrollOffsetModifier(coordinateSpace: coordinateSpace, onChange: perform))
    }
}

// Alternative approach using ScrollViewReader and different detection method
struct TodayView: View {
    @ObservedObject var model: Model
    @State var showDetails: Bool = false
    @State private var isAtTop: Bool = true
    var namespace: Namespace.ID
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 30) {
                        // Invisible marker at the top
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 1)
                            .id("top")
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear {
                                            // Set initial state
                                            // With contentMargins(.top, 180), the top marker starts at minY = 180
                                            let frame = geo.frame(in: .named("scroll"))
                                            let topMargin: CGFloat = 180
                                            let threshold: CGFloat = 10
                                            let isNowAtTop = frame.minY >= (topMargin - threshold)
                                            if isNowAtTop != model.isScrollingViewAtDefaultPosition {
                                                withAnimation {
                                                    model.isScrollingViewAtDefaultPosition = isNowAtTop
                                                }
                                            }
                                        }
                                        .onChange(of: geo.frame(in: .named("scroll")).minY) { _, newValue in
                                            // When at top with contentMargins(.top, 180), minY = 180
                                            // As you scroll down, minY decreases (179, 178, etc.)
                                            let topMargin: CGFloat = 140
                                            let threshold: CGFloat = 20
                                            let isNowAtTop = newValue >= (topMargin - threshold)
                                            //print("Top marker offset: \(newValue), topMargin: \(topMargin)")
                                            if isNowAtTop != model.isScrollingViewAtDefaultPosition {
                                                print("ScrollView isAtTop: \(isNowAtTop)")
                                                withAnimation {
                                                    model.isScrollingViewAtDefaultPosition = isNowAtTop
                                                }
                                            }
                                        }
                                }
                            )
                        
                        HStack {
                            Text("Lunch")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                        }
                        .padding(.bottom, -10)
                        
                        ForEach(model.lunchFood) { food in
                            FoodSuggestionRow(model: model, food: food, isLunch: true, isDinner: false, namespace: namespace)
                                .onTapGesture {
                                    withAnimation(.smooth(duration: 0.3)) {
                                        print("Selected food: \(food.name)")
                                        model.selectedFood = food
                                    }
                                }
                        }
                        
                        
                        HStack {
                            Text("Dinner")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                        }
                        .padding(.bottom, -10)
                        .padding(.top, 10)
                        ForEach(model.dinnerFood) { food in
                            FoodSuggestionRow(model: model, food: food, isLunch: false, isDinner: true, namespace: namespace)
                                .onTapGesture {
                                    withAnimation(.smooth(duration: 0.3)) {
                                        print("Selected food: \(food.name)")
                                        model.selectedFood = food
                                    }
                                }
                        }
                        
                        
                        
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(height: 200)
                    }
                    .padding()
                }
                .coordinateSpace(name: "scroll")
                .contentMargins(.top, 160)
                .scrollIndicators(.hidden)
//                .sheet(isPresented: $showDetails) {
//                    
//                }
            }
        }
    }
}
#Preview {
    ContentView(model: Model())
}

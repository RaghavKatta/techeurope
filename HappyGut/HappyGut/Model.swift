//
//  Untitled.swift
//  HappyGut
//
//  Created by Samuele Viganò on 24/05/25.
//

import SwiftUI



let baseUrl = "https://ba30-195-154-101-135.ngrok-free.app"

class Model: ObservableObject {
    enum Views: String, CaseIterable {
        case home = "house"
        case groceries = "cart"
        
        func title(view: Views) -> String {
            switch view {
            case .home:
                return "Today"
            case .groceries:
                return "Groceries"
            }
        }
    }
    
    @Published var currentView: Views = .home
    @Published var showAddView: Bool = false
    @Published var showGutScoreView: Bool = false
    
    @Published var showLogFood: Bool = false
    @Published var showLogPain: Bool = false
    
    @Published var todayFood: [Food] = [
        Food(image: "oats", name: "Overnight Oats", description: "A sweet red fruit", ingredients: "Apple", scoreImpact: 5),
        Food(image: "oats", name: "Overnight Oats", description: "A sweet red fruit", ingredients: "Apple", scoreImpact: 5),
        Food(image: "oats", name: "Overnight Oats", description: "A sweet red fruit", ingredients: "Apple", scoreImpact: 5),
        Food(image: "oats", name: "Overnight Oats", description: "A sweet red fruit", ingredients: "Apple", scoreImpact: 5),
        Food(image: "oats", name: "Overnight Oats", description: "A sweet red fruit", ingredients: "Apple", scoreImpact: 5),
        Food(image: "oats", name: "Overnight Oats", description: "A sweet red fruit", ingredients: "Apple", scoreImpact: 5),
        Food(image: "oats", name: "Overnight Oats", description: "A sweet red fruit", ingredients: "Apple", scoreImpact: 5),
        Food(image: "oats", name: "Overnight Oats", description: "A sweet red fruit", ingredients: "Apple", scoreImpact: 5)
    ]
    
    
    @Published var gutScore: Int = 80
    
    @Published var isScrollingViewAtDefaultPosition: Bool = true
    
    
    func updateFood(_ food: Food) {
        let index = todayFood.firstIndex(where: { $0.id == food.id })
        
        if let index = index {
            withAnimation {
                todayFood[index].isAdded.toggle()
                
                if todayFood[index].isAdded {
                    gutScore += todayFood[index].scoreImpact
                } else {
                    gutScore -= todayFood[index].scoreImpact
                }
            }
        }
    }
}
    

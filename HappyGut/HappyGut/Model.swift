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
    
    @Published var orderPlaced: Bool = false
    
    @Published var breakfastFood: [Food] = [
    ]
    
    
    @Published var selectedFood: Food?
    
    
    @Published var lunchFood: [Food] = [
        Food(
            image: "quinoa-salad",
            name: "Quinoa Salad",
            description: "A refreshing mix of quinoa and veggies 🥗",
            ingredients: """
            • 🌾 Quinoa\n\
            • 🥒 Cucumber\n\
            • 🍅 Cherry Tomatoes\n\
            • 🌿 Parsley\n\
            • 🍋 Lemon
            """,
            scoreImpact: 2
        ),
        Food(
            image: "vibrant-bowl",
            name: "Vibrant Bowl",
            description: "A colorful bowl of roasted veggies 🍠🥑",
            ingredients: """
            • 🍠 Sweet Potato\n\
            • 🥑 Avocado\n\
            • 🌰 Black Beans\n\
            • 🍚 Brown Rice
            """,
            scoreImpact: 3
        ),
        Food(
            image: "poelee-legumes",
            name: "Chicken & Veggies",
            description: "Grilled chicken with sautéed veggies 🍗🥦",
            ingredients: """
            • 🍗 Chicken Breast\n\
            • 🌶️ Bell Peppers\n\
            • 🥒 Zucchini\n\
            • 🧴 Olive Oil
            """,
            scoreImpact: 3
        )
    ]

    @Published var dinnerFood: [Food] = [
        Food(
            image: "fresh-spinach",
            name: "Vegan Burritos",
            description: "Plant-based wraps with beans and salsa 🌯",
            ingredients: """
            • 🌮 Tortilla\n\
            • 🌰 Black Beans\n\
            • 🌽 Corn\n\
            • 🥑 Avocado\n\
            • 🌶️ Salsa
            """,
            scoreImpact: 1
        ),
        Food(
            image: "smoothie-vert",
            name: "Green Smoothie",
            description: "A detoxifying green smoothie 🥬🍌",
            ingredients: """
            • 🥬 Spinach\n\
            • 🍌 Banana\n\
            • 🥛 Almond Milk\n\
            • 🌰 Chia Seeds
            """,
            scoreImpact: 2
        )
    ]
    
    @Published var gutScore: Int = 80
    
    @Published var isScrollingViewAtDefaultPosition: Bool = true
    
    
    func updateFood(_ food: Food, isBreakfast: Bool = false, isLunch: Bool = false, isDinner: Bool = false) {
        
        if isBreakfast {
            let index = breakfastFood.firstIndex(where: { $0.id == food.id })
            
            if let index = index {
                withAnimation {
                    breakfastFood[index].isAdded.toggle()
                    
                    if breakfastFood[index].isAdded {
                        gutScore += breakfastFood[index].scoreImpact
                    } else {
                        gutScore -= breakfastFood[index].scoreImpact
                    }
                }
            }
        } else if isLunch {
            let index = lunchFood.firstIndex(where: { $0.id == food.id })
            
            if let index = index {
                withAnimation {
                    lunchFood[index].isAdded.toggle()
                    
                    if lunchFood[index].isAdded {
                        gutScore += lunchFood[index].scoreImpact
                    } else {
                        gutScore -= lunchFood[index].scoreImpact
                    }
                }
            }
        } else if isDinner{
            let index = dinnerFood.firstIndex(where: { $0.id == food.id })
            
            if let index = index {
                withAnimation {
                    dinnerFood[index].isAdded.toggle()
                    
                    if dinnerFood[index].isAdded {
                        gutScore += dinnerFood[index].scoreImpact
                    } else {
                        gutScore -= dinnerFood[index].scoreImpact
                    }
                }
            }
        }
            
       
    }
    
    
}
    

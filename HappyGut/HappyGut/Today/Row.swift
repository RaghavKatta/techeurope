//
//  Row.swift
//  HappyGut
//
//  Created by Samuele Viganò on 24/05/25.
//

import SwiftUI



struct FoodLog: Identifiable {
    var image: String
    var name: String
    var id = UUID()
}


struct Food: Identifiable {
    var id = UUID()
    var image: String
    var name: String
    var description: String
    var ingredients: String
    
    var scoreImpact: Int
    
    var isAdded: Bool = false
}

//struct FoodSuggestion {
//    var Food: Food
//    var description: String
//    var id = UUID()
//    var isSelected: Bool = false
//    var isFavorite: Bool = false
//    var isBlacklisted: Bool = false
//    var isInGroceries: Bool = false
//    var isInHistory: Bool = false
//}


struct FoodSuggestionRow: View {
    @ObservedObject var model: Model
    var food: Food
    var isLunch: Bool = false
    var isDinner: Bool = false
    
    
    var namespace: Namespace.ID
    
    var body: some View {
        Capsule()
            .frame(height: 80)
            .foregroundStyle(.regularMaterial)
            .overlay {
                HStack {
                    ZStack {
                        Image(food.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .matchedGeometryEffect(id: food.image, in: namespace)
                            .frame(height: 120)
                    }
                    
                    Spacer()
                }
            }
            .overlay(content: {
                Text(food.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: 100, alignment: .leading)
                    .offset(x: -20)
            })
            .overlay(alignment: .trailing) {
                HStack {
                    Spacer()
                    
                    Text("+\(food.scoreImpact)")
                        .foregroundStyle(.green)
                        .font(.system(size: 20))
                        .bold()
                    
                    Circle()
                        .foregroundStyle(food.isAdded ? .green : .gray.opacity(0.3))
                        .overlay {
                            Image(systemName: food.isAdded ? "checkmark" : "plus")
                                .font(.system(size: 20))
                                .bold()
                                .foregroundStyle(food.isAdded ? .white : .black)
                        }
                        .onTapGesture {
                            model.updateFood(food, isLunch: isLunch, isDinner: isDinner)
                        }
                       
                }
                .padding()
                
            }
            
    }
    
}

#Preview {
    ZStack {
        FoodSuggestionRow(model: Model(), food: Food(image: "oats", name: "Overnight Oats", description: "A sweet red fruit", ingredients: "Apple", scoreImpact: 5), namespace: Namespace().wrappedValue)
            .padding()
    }
}


#Preview {
    ContentView()
}

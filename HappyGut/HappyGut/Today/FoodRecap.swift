//
//  FoodRecap.swift
//  HappyGut
//
//  Created by Samuele Viganò on 25/05/25.
//

import SwiftUI

struct FoodRecap: View {
    var food: Food
    
    var namespace: Namespace.ID
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .foregroundStyle(.white)
                .ignoresSafeArea()
                .frame(height: 550)
                .shadow(radius: 5)
                .overlay(alignment: .topTrailing, content: {
                    HStack {
                        VStack(spacing: 0) {
                            Text("70%")
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.secondary)
                            
                            Text("Match")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 13))
                                .bold()
                        }
                        
                        
                        Circle()
                            .foregroundStyle(.green)
                            .overlay {
                                Text("+\(food.scoreImpact)")
                                    .foregroundColor(.white)
                                    .font(.title)
                                    .bold()
                            }
                    }
                    .frame(height: 60)
                    .padding()
                })
                .overlay(alignment: .top) {
                    HStack {
                        ZStack {
                            Image(food.image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .matchedGeometryEffect(id: food.image, in: namespace)
                                .frame(height: 200)
                                .offset(x: -10)
                                
                        }
                       // .scaleEffect(1.8)
                       
                        .offset(x: -20)
                        
                        Spacer()
                
                    }
                    .padding(.top, -80)
                    .padding(.horizontal)
                }
                .overlay {
                    VStack() {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Gut Health")
                                    .foregroundStyle(.secondary)
                                    .font(.title)
                        
                                Text(food.name)
                            }
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.black)
                            Spacer()
                        }
                        
                        Spacer()
                            .frame(height: 20)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 20) {
                                Text(food.description)
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 16))
                                    .italic()
                                
                                VStack(alignment: .leading) {
                                    Text("Ingredients")
                                        .bold()
                                    
                                    
                                    Text("\(food.ingredients)")
                                        .foregroundStyle(.secondary)
                                        .font(.system(size: 16))
                                        .multilineTextAlignment(.leading)
                                        .padding(.top, 2)
                                        .padding(.leading)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 120)
                    .padding(.horizontal)
                }
                .overlay(alignment: .bottom) {
                    Button {
                    } label: {
                        Capsule()
                            .foregroundStyle(.black)
                            .frame(width: 200, height: 60)
                            
                            .overlay {
                                Text("Add to Meal")
                                    .foregroundColor(.white)
                                    .font(.title2)
                                    .bold()
                            }
                    }
                    .padding(.bottom, 20)
                }
        }
    }
}

//#Preview {
//    VStack {
//        Spacer()
//
//        FoodRecap(food: Food(, namespace: Namespace().wrappedValue)
//    }
//    .ignoresSafeArea()
//}

//
//  TabBar'.swift
//  HappyGut
//
//  Created by Samuele Viganò on 24/05/25.
//



import SwiftUI


struct TabBar: View {
    @ObservedObject var model: Model
    
    var body: some View {
        RoundedRectangle(cornerRadius: 0)
            .foregroundStyle(.regularMaterial)
            .overlay {
                HStack {
                    HStack {
                        ForEach(Model.Views.allCases, id: \.self) { view in
                            let systemImage = model.currentView.rawValue == view.rawValue ? view.rawValue + ".fill" : view.rawValue
                            
                            let isSelected = model.currentView.rawValue == view.rawValue
                            
                            VStack {
                                Button(view.rawValue, systemImage: systemImage) {
                                    withAnimation {
                                        model.currentView = view
                                    }
                                }
                                .labelStyle(.iconOnly)
                                .font(.system(size: 30))
                                .tint(.black.opacity(isSelected ? 0.7 : 0.3))
                                .frame(maxWidth: .infinity)
                                
                                //                                Text(view.title(view: view))
                                //                                    .font(.system(size: 12))
                                //                                    .foregroundStyle(.black.opacity(isSelected ? 0.7 : 0.3))
                            }
                        }
                    }
                    
                    Circle()
                        .foregroundStyle(.clear)
                        .frame(width: 120)
                    
                }
                .padding(.bottom, 20)
            }
            .frame(height: 100)
            .overlay(alignment: .trailing) {
                Button {
                    withAnimation {
                        model.showAddView.toggle()
                    }
                } label: {
                    Circle()
                        .foregroundStyle(.black)
                        .frame(width: 80)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 30))
                                .foregroundStyle(.white)
                                .bold()
                                .rotationEffect(.degrees(model.showAddView ? 45 : 0))
                        }
                }
                .buttonStyle(.plain)
                .padding(.top, -50)
                .padding(.trailing)
            }
    }
}

//#Preview {
//    ContentView()
//}

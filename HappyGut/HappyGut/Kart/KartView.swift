//
//  KartView.swift
//  HappyGut
//
//  Created by Samuele Viganò on 25/05/25.
//

import SwiftUI
import CoreLocation
import CoreLocationUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }
}

struct Store: Codable, Equatable {
    let name: String
    let address: String
    let price: String
    let healthiness_score: Int
}

struct KartView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var stores: [Store] = []
    @State private var isLoading = false
    @State private var selectedStore: Store?
    @ObservedObject var model: Model
    
    @State var waitingForConfirm = false
    
    @State var instructions: String = "Ring doorbell"
    
    var body: some View {
        if !model.orderPlaced {
            VStack() {
                Rectangle()
                    .ignoresSafeArea()
                    .foregroundStyle(.white)
                    .overlay {
                        ScrollView {
                            VStack(spacing: 16) {
                                
                                ScrollView(.horizontal) {
                                    LazyHStack(spacing: 20) {
                                        Image("avocat")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100)
                                            .overlay(alignment: .bottomTrailing) {
                                                Text("1€")
                                                    .foregroundStyle(.white)
                                                    .bold()
                                                    .padding()
                                                    .background(Circle().foregroundStyle(.green))
                                                    .offset(x: 10, y: 10)
                                                
                                            }
                                        
                                        Image("banane")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100)
                                            .overlay(alignment: .bottomTrailing) {
                                                Text("2€")
                                                    .foregroundStyle(.white)
                                                    .bold()
                                                    .padding()
                                                    .background(Circle().foregroundStyle(.green))
                                                    .offset(x: 10, y: 10)
                                                
                                                
                                            }
                                        
                                        Image("chocolate")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100)
                                            .overlay(alignment: .bottomTrailing) {
                                                Text("1€")
                                                    .foregroundStyle(.white)
                                                    .bold()
                                                    .padding()
                                                    .background(Circle().foregroundStyle(.green))
                                                    .offset(x: 10, y: 10)
                                                
                                            }
                                        
                                        Image("curcuma-root")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100)
                                            .overlay(alignment: .bottomTrailing) {
                                                Text("1.99€")
                                                    .foregroundStyle(.white)
                                                    .bold()
                                                    .padding()
                                                    .background(Circle().foregroundStyle(.green))
                                                    .offset(x: 10, y: 10)
                                                
                                            }
                                        
                                        Image("grilled-salmon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100)
                                            .overlay(alignment: .bottomTrailing) {
                                                Text("1.99€")
                                                    .foregroundStyle(.white)
                                                    .bold()
                                                    .padding()
                                                    .background(Circle().foregroundStyle(.green))
                                                    .offset(x: 10, y: 10)
                                                
                                            }
                                    }
                                    .frame(height: 130)
                                    .padding()
                                }
                                .frame(height: 200)
                                .scrollIndicators(.hidden)
                                
                                DisclosureGroup {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(stores, id: \.name) { store in
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(store.name)
                                                    .font(.headline)
                                                Text(store.address)
                                                    .font(.subheadline)
                                                Text("Price: \(store.price), Healthiness: \(store.healthiness_score)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .onTapGesture {
                                                selectedStore = store
                                            }
                                            //                                    .padding()
                                            //                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                                        }
                                    }
                                } label: {
                                    Label(selectedStore?.name ?? "Select a store", systemImage: "cart")
                                        .foregroundStyle(.black)
                                        .bold()
                                }
                                .padding(.horizontal)
                                
                             
                                
                                
                                DisclosureGroup {
                                    HStack {
                                        Text("12 Rue Martel, 75010 Paris")
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    .padding()
                                    
                                } label: {
                                    Label("La Cristallerie", systemImage: "location.fill")
                                        .foregroundStyle(.black)
                                        .bold()
                                }
                                .padding(.horizontal)
                                
    
                                
                                                                
                                DisclosureGroup {
                                    VStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .foregroundStyle(.regularMaterial)

                                            .overlay(alignment: .leading) {
                                                Text("Samuele Vigano")
                                                    .foregroundStyle(.secondary)
                                                    .padding()
                                                    
                                            }
                                        
                                        HStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .foregroundStyle(.regularMaterial)

                                                .overlay(alignment: .leading) {
                                                    Text("*************")
                                                        .foregroundStyle(.secondary)
                                                        .padding()
                                                }
                                            RoundedRectangle(cornerRadius: 16)
                                                .foregroundStyle(.regularMaterial)
                                                .overlay(alignment: .leading) {
                                                    Text("CVV")
                                                        .foregroundStyle(.secondary)
                                                        .padding()
                                                }
                                                .overlay(alignment: .trailing) {
                                                    Text("637")
                                                        .foregroundStyle(.secondary).padding()
                                                    
                                                        
                                                }
                                        }
                                    }
                                    .frame(height: 100)
                                    .padding()
                                    
                                } label: {
                                    Label("Mastercard *4179", systemImage: "creditcard")
                                        .foregroundStyle(.black)
                                        .bold()
                                }
                                .padding(.horizontal)
                                
                                
                                DisclosureGroup {
                                    RoundedRectangle(cornerRadius: 16)
                                        .foregroundStyle(.regularMaterial)
                                        .overlay(alignment: .leading) {
                                            Text("+33 07 64 500 258")
                                                .foregroundStyle(.secondary)
                                                .padding()
                                        }
                                        .frame(height: 50)
                                    
                                } label: {
                                    Label("+33 07 64 500 258", systemImage: "phone.fill")
                                        .foregroundStyle(.black)
                                        .bold()
                                }
                                .padding(.horizontal)
                                
                            
                            }
                        }
                        .contentMargins(.top, 150)
                        
                        
                        //   .padding(.horizontal)
                    }
                    .onChange(of: stores) { oldValue, newValue in
                        withAnimation {
                            selectedStore = newValue.first
                        }
                    }
            }
            .overlay(alignment: .bottom) {
                Button {
                    withAnimation {
                        waitingForConfirm.toggle()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            model.orderPlaced = true
                        }
                            
                    }
                } label: {
                 
                        Capsule()
                        .foregroundStyle(waitingForConfirm ? .gray : .black)
                            .frame(width: 250, height: 60)
                            .overlay {
                                if !waitingForConfirm {
                                    HStack {
                                        Spacer()
                                        
                                        Text("Order Now")
                                            .bold()
                                            .foregroundStyle(.white)
                                        
                                        Spacer()
                                        
                                        Capsule()
                                            .foregroundStyle(.white.opacity(0.15))
                                            .overlay {
                                                Text("10.99€")
                                                    .foregroundStyle(.white)
                                                
                                            }
                                            .frame(width: 100)
                                    }
                                    .padding(9)
                                } else {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                        
                                        
                                        Text("Confirming")
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                           
                
                    
                }
                .padding()
                .padding(.bottom, 70)
            }
            .onAppear {
                Task {
                    await fetchNearbyStores()
                }
                print("Fetching nearby stores...")
            }
        } else {
            OrderComing()
        }
    }

    func fetchNearbyStores() async {
        guard let url = URL(string: "\(baseUrl)/locations") else {
            print("Invalid URL")
            return
        }
        isLoading = true

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
            }
            guard let data = data, error == nil else {
                print("Network error:", error ?? "unknown")
                return
            }
            do {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Response JSON string: \(jsonString)")
                }
                let decodedStores = try JSONDecoder().decode([Store].self, from: data)
                DispatchQueue.main.async {
                    stores = decodedStores
                }
            } catch {
                print("Raw data:", data)
                if let raw = String(data: data, encoding: .utf8) {
                    print("Response as string:", raw)
                }
                print("JSON decode error:", error)
            }
        }.resume()
    }
}

#Preview {
    KartView(model: Model())
}




struct OrderComing: View {
    @State var animated = false
    
    var body: some View {
        Rectangle()
            .foregroundStyle(.white)
            .ignoresSafeArea()
            .overlay {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100))
                        .bold()
                        .foregroundStyle(.green)
                        .padding(.bottom, 30)
                    
                    Capsule()
                        .foregroundStyle(.regularMaterial)
                        .overlay {
                            Capsule()
                                .foregroundStyle(.black)
                                .frame(height: 5)
                                .offset(x: animated ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width)
                                .clipShape(Capsule())
                        }
                        .frame(height: 5)
                        .padding()
                        .clipShape(Capsule())
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                                animated.toggle()
                            }
                        }
                        
                        
                    Text("Your order is on its way!")
                        .font(.title)
                        .bold()
                    
                }
            }
    }
}

#Preview {
    OrderComing()
}

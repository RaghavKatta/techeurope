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

struct Store: Codable {
    let name: String
    let address: String
    let price: String
    let healthiness_score: Int
}

struct KartView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var stores: [Store] = []
    @State private var isLoading = false

    var body: some View {
        VStack {
            Rectangle()
                .ignoresSafeArea()
                .foregroundStyle(.white)
                .overlay {
                    if isLoading {                        
                        ProgressView("Loading stores...")
                    } else {
                        List(stores, id: \.name) { store in
                            VStack(alignment: .leading) {
                                Text(store.name).font(.headline)
                                Text(store.address).font(.subheadline)
                                Text("Price: \(store.price), Healthiness: \(store.healthiness_score)")
                                    .font(.caption)
                            }
                        }
                        .contentMargins(.top, 300)
                        
                    }
                }
        }
        .onAppear {
            Task {
                await fetchNearbyStores()
            }
            print("Fetching nearby stores...")
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
    KartView()
}

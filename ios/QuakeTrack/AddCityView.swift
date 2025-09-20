//
//  AddCityView.swift
//  QuakeTrack
//

import SwiftUI
import Combine

struct AddCityView: View {
    // Access the NotificationManager from the environment.
    @EnvironmentObject var notificationManager: NotificationManager
    var cityToEdit: NotificationCity?
    
    @Environment(\.dismiss) private var dismiss
    
    enum SearchState {
        case idle
        case searching
        case noResults
        case resultsFound([GeocodingService.GeoName])
    }
    
    @State private var searchQuery = ""
    @State private var searchState: SearchState = .idle
    @State private var selectedCity: GeocodingService.GeoName?
    
    @State private var radius: Double = 100
    @State private var unit: NotificationCity.DistanceUnit = .kilometers
    @State private var minMagnitude: Double = 1.0
    
    private let geocodingService = GeocodingService()
    
    var body: some View {
        // CORRECTED: The redundant NavigationView has been removed.
        Form {
            Section(header: Text("City")) {
                TextField("Search for a city", text: $searchQuery)
                    .onChange(of: searchQuery) {
                        let selectedCityText = selectedCity.map { "\($0.name), \($0.countryName)" }
                        
                        if searchQuery != selectedCityText {
                            selectedCity = nil
                            Task {
                                await performSearch()
                            }
                        }
                    }
                
                switch searchState {
                case .idle:
                    EmptyView()
                case .searching:
                    HStack {
                        ProgressView()
                        Text("Searching...")
                            .foregroundColor(.secondary)
                    }
                case .noResults:
                    Text("No cities found.")
                        .foregroundColor(.secondary)
                case .resultsFound(let cities):
                    List(cities) { city in
                        Button(action: {
                            selectedCity = city
                            searchQuery = "\(city.name), \(city.countryName)"
                            searchState = .idle
                        }) {
                            VStack(alignment: .leading) {
                                Text(city.name)
                                Text("\(city.countryName)\(city.adminName1 != nil ? ", \(city.adminName1!)" : "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            Section(header: Text("Notification Radius")) {
                HStack {
                    Slider(value: $radius, in: 20...1000, step: 20)
                    Text("\(Int(radius))")
                }
                Picker("Unit", selection: $unit) {
                    ForEach(NotificationCity.DistanceUnit.allCases) { unitCase in
                        Text(unitCase.rawValue).tag(unitCase)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Minimum Magnitude")) {
                Stepper(value: $minMagnitude, in: 1...10, step: 0.5) {
                    Text("Notify for quakes above magnitude \(String(format: "%.1f", minMagnitude))")
                }
            }
        }
        .navigationTitle(cityToEdit == nil ? "Add City" : "Edit City")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save", action: saveCity)
                    .disabled(selectedCity == nil && cityToEdit == nil)
            }
        }
        .onAppear(perform: setupForEditing)
    }
    
    private func performSearch() async {
        guard searchQuery.count > 2 else {
            searchState = .idle
            return
        }
        
        searchState = .searching
        
        do {
            let results = try await geocodingService.searchCities(query: searchQuery)
            if results.isEmpty {
                searchState = .noResults
            } else {
                searchState = .resultsFound(results)
            }
        } catch {
            print("Error searching cities: \(error)")
            searchState = .noResults
        }
    }
    
    private func setupForEditing() {
        guard let city = cityToEdit else { return }
        searchQuery = "\(city.name), \(city.country)"
        radius = city.radius
        unit = city.unit
        minMagnitude = city.minMagnitude ?? 1.0
        
        selectedCity = GeocodingService.GeoName(
            id: 0,
            name: city.name,
            countryName: city.country,
            adminName1: city.state,
            lat: String(city.latitude),
            lng: String(city.longitude)
        )
    }
    
    private func saveCity() {
        if let cityToEdit = cityToEdit, let selectedCity = selectedCity {
            var updatedCity = cityToEdit
            
            if let latitude = Double(selectedCity.lat), let longitude = Double(selectedCity.lng) {
                updatedCity.name = selectedCity.name
                updatedCity.country = selectedCity.countryName
                updatedCity.state = selectedCity.adminName1
                updatedCity.latitude = latitude
                updatedCity.longitude = longitude
            }
            
            updatedCity.radius = radius
            updatedCity.unit = unit
            updatedCity.minMagnitude = minMagnitude
            
            notificationManager.updateCity(updatedCity)
        }
        else if let selectedCity = selectedCity,
                let latitude = Double(selectedCity.lat),
                let longitude = Double(selectedCity.lng) {
            let newCity = NotificationCity(
                id: UUID(),
                name: selectedCity.name,
                country: selectedCity.countryName,
                state: selectedCity.adminName1,
                latitude: latitude,
                longitude: longitude,
                radius: radius,
                unit: unit,
                minMagnitude: minMagnitude
            )
            notificationManager.addCity(newCity)
        }
        
        dismiss()
    }
}

struct AddCityView_Previews: PreviewProvider {
    static var previews: some View {
        // CORRECTED: The preview now wraps the view in a NavigationView
        // and provides the required environment object to that container.
        NavigationView {
            AddCityView(cityToEdit: nil)
        }
        .environmentObject(NotificationManager.shared)
    }
}


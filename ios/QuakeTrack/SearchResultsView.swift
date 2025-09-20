// SearchResultsView.swift

import SwiftUI

struct SearchResultsView: View {
    
    enum SearchMode {
        case byYear, byDate
    }
    
    // Define the sorting options
    enum SortOption: String, CaseIterable, Identifiable {
        case byMagnitude = "By magnitude"
        case byTime = "By date/time"
        var id: Self { self }
    }
    
    let searchMode: SearchMode
    var selectedYear: Int?
    var selectedDate: Date?

    @State private var earthquakes: [Earthquake] = []
    @State private var isLoading: Bool = false
    @State private var searchMessage: String = "Searching..."
    
    // Add state to track the current sort option, defaulting to magnitude
    @State private var sortOption: SortOption = .byMagnitude
    
    // This computed property automatically returns the sorted list of earthquakes
    // based on the current sortOption.
    private var sortedEarthquakes: [Earthquake] {
        switch sortOption {
        case .byMagnitude:
            // Sort by magnitude, descending (largest first)
            return earthquakes.sorted { ($0.properties.mag ?? 0) > ($1.properties.mag ?? 0) }
        case .byTime:
            // Sort by time, descending (newest first)
            return earthquakes.sorted { ($0.properties.time ?? 0) > ($1.properties.time ?? 0) }
        }
    }

    var body: some View {
        VStack {
            if isLoading {
                Spacer()
                ProgressView(searchMessage)
                Spacer()
            } else {
                if earthquakes.isEmpty {
                    Spacer()
                    Text(searchMessage)
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    // The List now iterates over the sortedEarthquakes computed property
                    List(sortedEarthquakes) { quake in
                        NavigationLink(destination: EarthquakeDetailView(earthquake: quake)) {
                            EarthquakeTileView(earthquake: quake)
                        }
                    }
                }
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: fetchEarthquakes)
        // Add a toolbar to hold the new sorting menu
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // A Picker is a great way to manage selection state in a Menu
                    Picker("Sort by", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
    }

    // MARK: - NETWORKING LOGIC
    func fetchEarthquakes() {
        isLoading = true
        earthquakes = []
        
        let baseURL = "https://earthquake.usgs.gov/fdsnws/event/1/query"
        var components = URLComponents(string: baseURL)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // The default `orderby` parameter in the API call remains the same.
        // The new sorting logic is handled entirely within the app for instant feedback.
        if searchMode == .byYear, let year = selectedYear {
            searchMessage = "Fetching earthquakes for \(year)..."
            components.queryItems = [
                URLQueryItem(name: "format", value: "geojson"),
                URLQueryItem(name: "starttime", value: "\(year)-01-01"),
                URLQueryItem(name: "endtime", value: "\(year)-12-31"),
                URLQueryItem(name: "minmagnitude", value: "4.0"),
                URLQueryItem(name: "orderby", value: "magnitude"),
                URLQueryItem(name: "limit", value: "20")
            ]
        } else if let date = selectedDate {
            let startDateString = dateFormatter.string(from: date)
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            let endDateString = dateFormatter.string(from: nextDay)
            searchMessage = "Fetching earthquakes for \(startDateString)..."

            components.queryItems = [
                URLQueryItem(name: "format", value: "geojson"),
                URLQueryItem(name: "starttime", value: startDateString),
                URLQueryItem(name: "endtime", value: endDateString),
                URLQueryItem(name: "orderby", value: "magnitude")
            ]
        }
        
        guard let url = components.url else {
            searchMessage = "Invalid URL created."
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let data = data, let decodedResponse = try? JSONDecoder().decode(USGSResponse.self, from: data) {
                    if decodedResponse.features.isEmpty {
                        searchMessage = "No earthquakes found for your criteria."
                    } else {
                        self.earthquakes = decodedResponse.features.map(Earthquake.init)
                    }
                } else {
                    searchMessage = "Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }.resume()
    }
}

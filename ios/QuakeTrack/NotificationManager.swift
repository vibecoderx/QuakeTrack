//
//  NotificationManager.swift
//  QuakeTrack
//

import Foundation
import CoreLocation
import SwiftUI
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let citiesDefaultsKey = "notification_cities"
    
    @Published var cities: [NotificationCity] = []
    @Published var unreadAlerts: [Earthquake] = []
    @Published var selectedEarthquake: Earthquake? = nil
    @Published var fcmToken: String?
    
    private init() {
        loadCities()
    }
    
    // MARK: - City Management & Syncing
    func addCity(_ city: NotificationCity) {
        cities.append(city)
        saveAndSync()
    }
    
    func updateCity(_ city: NotificationCity) {
        if let index = cities.firstIndex(where: { $0.id == city.id }) {
            cities[index] = city
            saveAndSync()
        }
    }

    func deleteCity(at offsets: IndexSet) {
        cities.remove(atOffsets: offsets)
        saveAndSync()
    }
    
    private func saveAndSync() {
        saveCities()
        syncPreferencesToServer()
    }
    
    private func saveCities() {
        if let encoded = try? JSONEncoder().encode(cities) {
            UserDefaults.standard.set(encoded, forKey: citiesDefaultsKey)
        }
    }
    
    private func loadCities() {
        if let savedCities = UserDefaults.standard.data(forKey: citiesDefaultsKey) {
            if let decodedCities = try? JSONDecoder().decode([NotificationCity].self, from: savedCities) {
                self.cities = decodedCities
                return
            }
        }
        self.cities = []
    }

    // MARK: - Server Communication
    func updateFCMToken(_ token: String?) {
        self.fcmToken = token
    }
    
    @MainActor
    func fetchUnreadAlerts() async {
        print("Fetching unread alerts from server...")
        guard let token = fcmToken else {
            print("Cannot fetch alerts: FCM token is missing.")
            return
        }
        
        guard var urlComponents = URLComponents(string: Secrets.getUnreadAlertsURL) else {
            return
        }
        urlComponents.queryItems = [URLQueryItem(name: "fcm_token", value: token)]
        guard let url = urlComponents.url else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct AlertsResponse: Codable { let alerts: [EarthquakeFeature] }
            let response = try JSONDecoder().decode(AlertsResponse.self, from: data)
            
            let sortedQuakes = response.alerts.map(Earthquake.init).sorted {
                ($0.properties.time ?? 0) > ($1.properties.time ?? 0)
            }
            
            self.unreadAlerts = sortedQuakes
            
            try await UNUserNotificationCenter.current().setBadgeCount(self.unreadAlerts.count)
            print("Successfully fetched and set badge to \(self.unreadAlerts.count).")
            
        } catch {
            print("Failed to fetch, decode, or set badge: \(error)")
        }
    }

    @MainActor
    func clearAllAlerts() async {
        print("Telling server to clear alerts and clearing local state.")
        self.unreadAlerts.removeAll()
        
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(0)
        } catch {
            print("Failed to clear badge count: \(error)")
        }
        
        guard let token = fcmToken else { return }
        guard let url = URL(string: Secrets.clearUserAlertsURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ["fcm_token": token]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request).resume()
    }
    
    private func syncPreferencesToServer() {
        guard let token = fcmToken else { return }
        guard let url = URL(string: Secrets.updateUserPreferencesUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "fcm_token": token,
            "cities": cities.map { city in
                return [
                    "id": city.id.uuidString,
                    "latitude": city.latitude,
                    "longitude": city.longitude,
                    "radius_km": city.unit == .kilometers ? city.radius : city.radius * 1.60934,
                    "min_magnitude": city.minMagnitude ?? 0.0
                ]
            }
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        URLSession.shared.dataTask(with: request).resume()
    }
    
    func fetchEarthquake(withId earthquakeID: String) async -> Earthquake? {
        let urlString = "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&eventid=\(earthquakeID)"
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let feature = try JSONDecoder().decode(EarthquakeFeature.self, from: data)
            return Earthquake(feature: feature)
        } catch {
            return nil
        }
    }
}


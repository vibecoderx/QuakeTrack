//
//  GeocodingService.swift
//  QuakeTrack
//

import Foundation

struct GeocodingService {
    
    // MARK: - Data Models for Decoding GeoNames API Response
    struct GeoNamesResponse: Codable {
        let geonames: [GeoName]
    }

    struct GeoName: Codable, Identifiable {
        let id: Int
        let name: String
        let countryName: String
        let adminName1: String? // State or province
        let lat: String
        let lng: String

        // Mapping API keys to struct properties
        private enum CodingKeys: String, CodingKey {
            case id = "geonameId"
            case name, countryName, adminName1, lat, lng
        }
    }
    
    // MARK: - API Search Function
    func searchCities(query: String) async throws -> [GeoName] {
        var components = URLComponents()
        components.scheme = "http" // GeoNames free tier uses http
        components.host = "api.geonames.org"
        components.path = "/searchJSON"
        
        components.queryItems = [
            URLQueryItem(name: "name_startsWith", value: query), // CORRECTED: Use "name_startsWith" for autocomplete
            URLQueryItem(name: "maxRows", value: "10"),
            URLQueryItem(name: "username", value: Secrets.geonamesUsername),
            URLQueryItem(name: "featureClass", value: "P") // P: populated place
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        // HELPFUL FOR DEBUGGING: This will print the exact URL to the console.
        print("Requesting URL: \(url.absoluteString)")

        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(GeoNamesResponse.self, from: data)
        
        return response.geonames
    }
}


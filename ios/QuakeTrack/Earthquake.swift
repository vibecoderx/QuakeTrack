//
//  Earthquake.swift
//  QuakeTrack
//

import Foundation
import CoreLocation

// MARK: - DATA MODELS
// These structures match the JSON from USGS so we can decode it.

struct USGSResponse: Codable {
    let features: [EarthquakeFeature]
}

struct EarthquakeFeature: Codable, Identifiable {
    let id: String
    let properties: EarthquakeProperties
    let geometry: Geometry
}

struct EarthquakeProperties: Codable {
    let mag: Double?
    let place: String?
    let time: Double?
    let alert: String?
    let tsunami: Int?
    let url: String?
    let type: String?
    let title: String?
}

struct Geometry: Codable {
    let coordinates: [Double]
}

// This is the main data structure we'll use inside the app.
struct Earthquake: Identifiable, Equatable, Hashable {
    let id: String
    let properties: EarthquakeProperties
    let coordinate: CLLocationCoordinate2D
    let url: String?

    init(feature: EarthquakeFeature) {
        self.id = feature.id
        self.properties = feature.properties
        self.coordinate = CLLocationCoordinate2D(
            latitude: feature.geometry.coordinates[1],
            longitude: feature.geometry.coordinates[0]
        )
        self.url = feature.properties.url
    }
    
    // Equatable conformance
    static func == (lhs: Earthquake, rhs: Earthquake) -> Bool {
        lhs.id == rhs.id
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Helper property to format the time for the main list view
    var formattedTimeForList: String {
        guard let timeValue = properties.time else { return "N/A" }
        let date = Date(timeIntervalSince1970: timeValue / 1000)
        
        let utcFormatter = DateFormatter()
        utcFormatter.timeStyle = .short
        utcFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        return utcFormatter.string(from: date) + " UTC"
    }
    
    // Helper property to format the full date and time for the detail view
    var formattedTimeForDetail: String {
        guard let timeValue = properties.time else { return "N/A" }
        let date = Date(timeIntervalSince1970: timeValue / 1000)
        
        let utcFormatter = DateFormatter()
        utcFormatter.dateStyle = .long
        utcFormatter.timeStyle = .short
        utcFormatter.timeZone = TimeZone(abbreviation: "UTC")

        return utcFormatter.string(from: date) + " (UTC)"
    }
}

// CLLocationCoordinate2D does not conform to Codable by default.
// We add this extension to make our Earthquake struct Codable.
// CORRECTED: Added @retroactive and the required Equatable function.
extension CLLocationCoordinate2D: Codable, @retroactive Hashable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}


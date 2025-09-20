//
//  NotificationCity.swift
//  QuakeTrack
//

import Foundation
import CoreLocation

struct NotificationCity: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var country: String
    var state: String?
    var latitude: Double
    var longitude: Double
    var radius: Double // Always stored in meters internally
    var unit: DistanceUnit
    var minMagnitude: Double?

    enum DistanceUnit: String, Codable, CaseIterable, Identifiable {
        case kilometers = "km"
        case miles = "mi"
        var id: Self { self }
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    // Equatable conformance
    static func == (lhs: NotificationCity, rhs: NotificationCity) -> Bool {
        lhs.id == rhs.id
    }
}


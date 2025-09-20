// EarthquakeTileView.swift

import SwiftUI
import MapKit

struct EarthquakeTileView: View {
    let earthquake: Earthquake

    private func alertColor(for level: String?) -> Color {
        switch level?.lowercased() {
        case "green": .green
        case "yellow": .yellow
        case "orange": .orange
        case "red": .red
        default: .gray
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(earthquake.properties.place ?? "Unknown location")
                    .font(.headline)
                Text("Magnitude: \(earthquake.properties.mag ?? 0, specifier: "%.2f")")
                Text("Time: \(earthquake.formattedTimeForList)")
                
                HStack {
                    Text("Alert: \(earthquake.properties.alert ?? "None")")
                        .font(.caption)
                        .padding(5)
                        .background(alertColor(for: earthquake.properties.alert).opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                    
                    Text("Tsunami: \((earthquake.properties.tsunami ?? 0) == 1 ? "Yes" : "No")")
                        .font(.caption)
                        .padding(5)
                        .background(((earthquake.properties.tsunami ?? 0) == 1 ? Color.red : Color.green).opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
            }
            
            Spacer()
            
            StaticMapView(coordinate: earthquake.coordinate)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
        }
        .padding(.vertical, 5)
    }
}


// MARK: - Static Map Helper View
private struct StaticMapView: View {
    let coordinate: CLLocationCoordinate2D
    @State private var position: MapCameraPosition

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )))
    }

    var body: some View {
        // CORRECTED: Pass the interaction modes directly into the initializer.
        // This is a more stable way to declare a non-interactive map.
        Map(position: $position, interactionModes: []) {
            Marker("", coordinate: coordinate)
                .tint(.red)
        }
    }
}


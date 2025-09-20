// EarthquakeDetailView.swift

import SwiftUI
import MapKit

struct EarthquakeDetailView: View {
    let earthquake: Earthquake
    
    // Use the modern MapCameraPosition for state
    @State private var position: MapCameraPosition

    init(earthquake: Earthquake) {
        self.earthquake = earthquake
        // Initialize the state with the earthquake's location
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: earthquake.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )))
    }
    
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Pass the new position binding to the MapView
                MapView(position: $position, coordinate: earthquake.coordinate)
                
                DetailsView(earthquake: earthquake, alertColor: alertColor(for: earthquake.properties.alert))
            }
            .padding()
        }
        .navigationTitle(earthquake.properties.place ?? "Earthquake Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Detail View Subcomponents

private struct MapView: View {
    // This view now accepts a binding to a MapCameraPosition
    @Binding var position: MapCameraPosition
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        // Use the modern Map initializer with a MapContentBuilder
        Map(position: $position) {
            // Use the modern Marker
            Marker("", coordinate: coordinate)
                .tint(.red)
        }
        .frame(height: 300)
        .cornerRadius(12)
        .overlay(alignment: .bottomTrailing) {
            Button(action: {
                withAnimation {
                    // Update the position to re-center the map
                    position = .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
                    ))
                }
            }) {
                Image(systemName: "location.fill")
                    .padding(10)
                    .background(.regularMaterial)
                    .clipShape(Circle())
            }
            .padding()
        }
    }
}

private struct DetailsView: View {
    let earthquake: Earthquake
    let alertColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Details")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            HStack(alignment: .top, spacing: 10) {
                DetailCard(icon: "waveform.path.ecg", label: "Magnitude", value: String(format: "%.2f", earthquake.properties.mag ?? 0), iconColor: .accentColor)
                
                DetailCard(icon: "exclamationmark.triangle.fill", label: "Alert", value: earthquake.properties.alert?.capitalized ?? "None", iconColor: alertColor)
                
                let tsunamiValue = (earthquake.properties.tsunami ?? 0) == 1 ? "Yes" : "No"
                let tsunamiColor: Color = (earthquake.properties.tsunami ?? 0) == 1 ? .red : .green
                DetailCard(icon: "water.waves", label: "Tsunami", value: tsunamiValue, valueColor: tsunamiColor, iconColor: .blue)
            }
            .padding(.vertical)

            Divider()
            
            VStack(alignment: .leading, spacing: 18) {
                SingleDetailRow(icon: "calendar", label: "Date & Time", value: earthquake.formattedTimeForDetail)
                let latString = String(format: "%.4f", earthquake.coordinate.latitude)
                let lonString = String(format: "%.4f", earthquake.coordinate.longitude)
                SingleDetailRow(icon: "location.fill", label: "Location", value: "Lat: \(latString), Lon: \(lonString)")
                SingleDetailRow(icon: "text.alignleft", label: "Full Title", value: earthquake.properties.title ?? "N/A")
            }
            
            if let urlString = earthquake.url, let url = URL(string: urlString) {
                Divider().padding(.vertical, 10)
                Link(destination: url) {
                    HStack {
                        Text("More details on USGS")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Helper Detail Views
private struct DetailCard: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical)
        .padding(.horizontal, 5)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .cornerRadius(10)
    }
}

private struct SingleDetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                Text(label)
                    .font(.headline)
            }
            Text(value)
                .font(.body)
                .padding(.leading, 28)
                .foregroundColor(.secondary)
        }
    }
}


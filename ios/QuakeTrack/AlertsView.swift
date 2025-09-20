//
//  AlertsView.swift
//  QuakeTrack
//

import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var isAddCitySheetPresented = false
    @State private var cityToEdit: NotificationCity?
    @State private var isDetailViewActive = false
    @State private var isAboutSheetPresented = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Recent Alerts"),
                        footer: Text(notificationManager.unreadAlerts.isEmpty ? "You have no new earthquake alerts." : "")) {
                    
                    if !notificationManager.unreadAlerts.isEmpty {
                        Button(action: {
                            // This now calls the unified clear function
                            Task {
                                await notificationManager.clearAllAlerts()
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text("Clear All Alerts")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                    
                    ForEach(notificationManager.unreadAlerts) { quake in
                        NavigationLink(destination: EarthquakeDetailView(earthquake: quake)) {
                            EarthquakeTileView(earthquake: quake)
                        }
                    }
                }
                Section(header: Text("Monitored Cities")) {
                    ForEach(notificationManager.cities) { city in
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(city.name)
                                    .font(.headline)
                                Text("\(city.country)\(city.state != nil ? ", \(city.state!)" : "")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Radius: \(Int(city.radius)) \(city.unit.rawValue) | Min. Mag: \(String(format: "%.1f", city.minMagnitude ?? 0.0))")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            cityToEdit = city
                            isAddCitySheetPresented = true
                        }
                    }
                    .onDelete(perform: notificationManager.deleteCity)
                }
            }
            .navigationDestination(isPresented: $isDetailViewActive) {
                if let earthquake = notificationManager.selectedEarthquake {
                    EarthquakeDetailView(earthquake: earthquake)
                }
            }
            .navigationTitle("Alerts & Cities")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isAboutSheetPresented = true
                    }) {
                        Image(systemName: "info.circle")
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EditButton()
                    Button(action: {
                        cityToEdit = nil
                        isAddCitySheetPresented = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddCitySheetPresented) {
                NavigationView {
                    AddCityView(cityToEdit: cityToEdit)
                        .environmentObject(notificationManager)
                }
            }
            .sheet(isPresented: $isAboutSheetPresented) {
                AboutView()
            }
            .onChange(of: notificationManager.selectedEarthquake) {
                isDetailViewActive = notificationManager.selectedEarthquake != nil
            }
            .onChange(of: isDetailViewActive) {
                if !isDetailViewActive {
                    notificationManager.selectedEarthquake = nil
                }
            }
        }
    }
}

struct AlertsView_Previews: PreviewProvider {
    static var previews: some View {
        AlertsView()
            .environmentObject(NotificationManager.shared)
    }
}


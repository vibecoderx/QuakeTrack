//
//  ContentView.swift
//  QuakeTrack
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    
    // State to control which tab is currently selected.
    @State private var selectedTab: Tab = .search

    enum Tab {
        case search
        case alerts
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: A unified search interface
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)

            // Tab 2: A view for unread alerts and managing cities
            AlertsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell.fill")
                }
                .tag(Tab.alerts)
        }
        // This is the deep-linking logic. When a notification is tapped,
        // the selectedEarthquake is set, and we switch to the Alerts tab.
        // The AlertsView itself will handle the navigation to the detail view.
        .onChange(of: notificationManager.selectedEarthquake) {
            if notificationManager.selectedEarthquake != nil {
                selectedTab = .alerts
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NotificationManager.shared)
    }
}


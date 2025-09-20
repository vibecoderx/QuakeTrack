//
//  QuakeTrackApp.swift
//  QuakeTrack
//

import SwiftUI
import UserNotifications

@main
struct QuakeTrackApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NotificationManager.shared)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // When the app becomes active, it fetches the latest alerts.
                // The fetch function itself is now responsible for updating the badge count.
                Task {
                    await NotificationManager.shared.fetchUnreadAlerts()
                }
            }
        }
    }
}


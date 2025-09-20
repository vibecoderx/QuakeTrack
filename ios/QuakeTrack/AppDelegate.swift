//
//  AppDelegate.swift
//  QuakeTrack
//

import UIKit
import Firebase
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        application.registerForRemoteNotifications()
        
        return true
    }

    // MARK: - FCM Token Handling
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("Firebase registration token: \(token)")
            NotificationManager.shared.updateFCMToken(token)
            
            Task {
                await NotificationManager.shared.fetchUnreadAlerts()
            }
        }
    }

    // MARK: - APNs Token Handling
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("Successfully registered for remote notifications with APNs token.")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - Notification Delegate Methods
    
    // This is called when a notification arrives while the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        handleIncomingNotification(userInfo: notification.request.content.userInfo)
        completionHandler([.banner, .sound])
    }
    
    // This is called when a user taps on a notification.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        handleIncomingNotification(userInfo: response.notification.request.content.userInfo, isTap: true)
        completionHandler()
    }
    
    // This is called for "silent" notifications when the app is in the background.
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("Received silent notification in background.")
        handleIncomingNotification(userInfo: userInfo)
        completionHandler(.newData)
    }

    private func handleIncomingNotification(userInfo: [AnyHashable: Any], isTap: Bool = false) {
        print("Handling incoming notification. Was tapped: \(isTap)")
        
        // Always refresh the unread alerts list from the server.
        Task {
            await NotificationManager.shared.fetchUnreadAlerts()
        }
        
        // If the notification was tapped, handle the deep link.
        if isTap, let earthquakeID = userInfo["earthquakeID"] as? String {
            Task {
                if let earthquake = await NotificationManager.shared.fetchEarthquake(withId: earthquakeID) {
                    await MainActor.run {
                        NotificationManager.shared.selectedEarthquake = earthquake
                    }
                }
            }
        }
    }
}


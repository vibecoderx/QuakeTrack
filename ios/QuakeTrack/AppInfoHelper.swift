//
//  AppInfoHelper.swift
//  QuakeTrack
//

import Foundation

struct AppInfoHelper {
    
    // A static computed property to get the app's version and build number.
    // This can be accessed from anywhere in the app via `AppInfoHelper.versionInfo`.
    static var versionInfo: String {
        // Access the app's main bundle and its Info.plist dictionary.
        guard let dictionary = Bundle.main.infoDictionary else {
            return "N/A"
        }
        
        // Retrieve the marketing version (e.g., "1.7").
        let version = dictionary["CFBundleShortVersionString"] as? String ?? "N/A"
        
        // Retrieve the build number (e.g., the Git commit hash).
        let build = dictionary["CFBundleVersion"] as? String ?? "N/A"
        
        return "Version: \(version) (Build: \(build))"
    }
}

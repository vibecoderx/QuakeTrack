//
//  File.swift
//  QuakeTrack
//

import Foundation

enum Secrets {
    static var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "APIKey") as? String else {
            fatalError("APIKey must be set in Info.plist.")
        }
        return key
    }

    static var geonamesUsername: String {
        guard let username = Bundle.main.object(forInfoDictionaryKey: "GeoNamesUsername") as? String else {
            fatalError("GeoNamesUsername must be set in Info.plist.")
        }
        return username
    }
    
    static var updateUserPreferencesUrl: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "UpdateUserPreferencesUrl") as? String else {
            fatalError("UpdateUserPreferencesUrl must be set in Info.plist.")
        }
        return url
    }
    
    static var getUnreadAlertsURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "GetUnreadAlertsURL") as? String else {
            fatalError("GetUnreadAlertsURL must be set in Info.plist.")
        }
        return url
    }
    
    static var clearUserAlertsURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "ClearUserAlertsURL") as? String else {
            fatalError("ClearUserAlertsURL must be set in Info.plist.")
        }
        return url
    }
}


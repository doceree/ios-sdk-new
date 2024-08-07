//
//  Header.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 30/05/24.
//

import Foundation
import AdSupport
import UIKit

class Header {

    init() {}

    func getHeaders() async throws -> [String: String] {
        do {
            let adInfo = try await getAdvertisingId()
            let appInfo = try await getAppInfo()
            
            let deviceInfoState: [String: String] = [
                "Content-Type": "application/json; charset=UTF-8",
                "doceree-device-id": adInfo.advertisingId,
                "is-ad-tracking-enabled": String(adInfo.adTrackingEnabled),
                "app-name": appInfo.appName,
                "app-version": appInfo.version,
                "lib-version": "5.0.5-4-gbbaaa60",
                "app-bundle": appInfo.bundleId
            ]
            
            return deviceInfoState
        } catch {
            print("Error fetching device info: \(error)")
            throw error
        }
    }

    func getAdvertisingId() async throws -> Advertisement {
        return try await withCheckedThrowingContinuation { continuation in
            let manager = ASIdentifierManager.shared()
            if manager.isAdvertisingTrackingEnabled {
                let adId = manager.advertisingIdentifier.uuidString
                let advertisement = Advertisement(advertisingId: adId, adTrackingEnabled: true)
                continuation.resume(returning: advertisement)
            } else {
                let advertisement = Advertisement(advertisingId: "", adTrackingEnabled: false)
                continuation.resume(returning: advertisement)
            }
        }
    }

    func getAppInfo() async throws -> AppInfo {
        return try await withCheckedThrowingContinuation { continuation in
            if let infoDict = Bundle.main.infoDictionary {
                let appName = infoDict["CFBundleName"] as? String ?? "Unknown"
                let version = infoDict["CFBundleShortVersionString"] as? String ?? "Unknown"
                let bundleId = infoDict["CFBundleIdentifier"] as? String ?? "Unknown"
                
                let appInfo = AppInfo(appName: appName, version: version, bundleId: bundleId)
                continuation.resume(returning: appInfo)
            } else {
                continuation.resume(throwing: NSError(domain: "AppInfoError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve app info"]))
            }
        }
    }
}

// Placeholder for Advertisement struct
struct Advertisement {
    let advertisingId: String
    let adTrackingEnabled: Bool
}

// Placeholder for AppInfo struct
struct AppInfo {
    let appName: String
    let version: String
    let bundleId: String
}

// Usage example:
// let header = Header()
// Task {
//     do {
//         let headers = try await header.getHeaders()
//         print(headers)
//     } catch {
//         print("Failed to get headers: \(error)")
//     }
// }

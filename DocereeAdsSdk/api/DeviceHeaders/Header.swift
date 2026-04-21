//
//  Header.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 30/05/24.
//

import Foundation
import AdSupport
import AppTrackingTransparency
import UIKit

class Header {
    private enum HeaderKeys {
        static let contentType = "Content-Type"
        static let deviceIdentifier = "doceree-device-id"
        static let adTrackingEnabled = "is-ad-tracking-enabled"
        static let appName = "app-name"
        static let appVersion = "app-version"
        static let libraryVersion = "lib-version"
        static let appBundle = "app-bundle"
    }
    private static let contentTypeValue = "application/json; charset=UTF-8"
    private static let sdkVersionValue = "5.0.5-4-gbbaaa60"
    private static let unknownValue = "Unknown"

    func getHeaders() async throws -> [String: String] {
        do {
            let adInfo = try await getAdvertisingId()
            let appInfo = try await getAppInfo()
            return makeDeviceHeaders(advertisement: adInfo, appInfo: appInfo)
        } catch {
            DocereeLog.debug("Error fetching device info: \(error)")
            throw error
        }
    }

    func getAdvertisingId() async throws -> Advertisement {
        let isTrackingAuthorized = ATTrackingManager.trackingAuthorizationStatus == .authorized
        let adId = isTrackingAuthorized ? ASIdentifierManager.shared().advertisingIdentifier.uuidString : ""
        return Advertisement(advertisingId: adId, adTrackingEnabled: isTrackingAuthorized)
    }

    func getAppInfo() async throws -> AppInfo {
        guard let infoDict = Bundle.main.infoDictionary else {
            throw NSError(
                domain: "AppInfoError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve app info"]
            )
        }

        let appName = infoDict["CFBundleName"] as? String ?? Self.unknownValue
        let version = infoDict["CFBundleShortVersionString"] as? String ?? Self.unknownValue
        let bundleId = infoDict["CFBundleIdentifier"] as? String ?? Self.unknownValue
        return AppInfo(appName: appName, version: version, bundleId: bundleId)
    }

    private func makeDeviceHeaders(advertisement: Advertisement, appInfo: AppInfo) -> [String: String] {
        [
            HeaderKeys.contentType: Self.contentTypeValue,
            HeaderKeys.deviceIdentifier: advertisement.advertisingId,
            HeaderKeys.adTrackingEnabled: String(advertisement.adTrackingEnabled),
            HeaderKeys.appName: appInfo.appName,
            HeaderKeys.appVersion: appInfo.version,
            HeaderKeys.libraryVersion: Self.sdkVersionValue,
            HeaderKeys.appBundle: appInfo.bundleId
        ]
    }
}

struct Advertisement {
    let advertisingId: String
    let adTrackingEnabled: Bool
}

struct AppInfo {
    let appName: String
    let version: String
    let bundleId: String
}

//
//  DocereeMobileAds.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 19/05/22.
//

import Foundation
#if canImport(AdSupport) && canImport(AppTrackingTransparency)
import AppTrackingTransparency
import AdSupport
import UIKit
#endif
import os.log

public final class DocereeMobileAds {
    
    internal static var trackingStatus: String = "not determined"
    public static var collectDataStatus = true

    /// When `true`, the SDK emits `os_signpost` intervals for key operations (see Instruments → Points of interest / system trace). Default is `true` in `DEBUG` and `false` in Release.
    public static var isSignpostEnabled: Bool {
        get { DocereeSignposts.isEnabled }
        set { DocereeSignposts.isEnabled = newValue }
    }

    private var environmentType = EnvironmentType.Prod
    
    private static var sharedNetworkManager: DocereeMobileAds = {
        var docereeMobileAds = DocereeMobileAds()
        return docereeMobileAds
    }()
    
    public func setEnvironment(type: EnvironmentType) {
        environmentType = type
    }
    
    public func getEnvironment() -> EnvironmentType {
        return environmentType
    }
    
    public static func login(with builder: DocereeProfileBuilding) {
        let role = inferredRole(from: builder)
        let profile = builder.build().applyingRole(role)
        login(with: profile, role: role)
    }

    @available(*, deprecated, message: "Use login(with: DocereeProfileBuilding). Pass HcpBuilder, HealthAssociateBuilder, or UserBuilder — the SDK infers role automatically.")
    public static func login(with hcp: Hcp) {
        login(with: hcp, role: hcp.role)
    }

    private static func inferredRole(from builder: DocereeProfileBuilding) -> DocereeUserRole {
        switch builder {
        case is HcpBuilder:
            return .hcp
        case is HealthAssociateBuilder:
            return .ha
        case is UserBuilder:
            return .user
        default:
            return .hcp
        }
    }

    private static func login(with profile: Hcp, role: DocereeUserRole) {
        UserDefaultsManager.shared.saveLoggedInProfile(profile, role: role)
        removeLegacyProfileArchiveIfPresent()
        DocereeMobileAds.shared().omInitialization()
    }

    private static func removeLegacyProfileArchiveIfPresent() {
        guard FileManager.default.fileExists(atPath: ProfileArchivingUrl.path) else { return }
        try? FileManager.default.removeItem(at: ProfileArchivingUrl)
    }

    func loadAppConfiguration() async {
        let appId = getBundleIdentifier()
        let outcome = await ConfigurationService.shared.fetchAppConfiguration(appId: appId)
        switch outcome {
        case .usedValidCache:
            DocereeLog.debug("App config: using valid cache")
        case .cancelled:
            DocereeLog.debug("App config: cancelled")
        case .missingApplicationKey:
            DocereeLog.debug("App config: missing application key")
        case .invalidConfigurationURL(let environment, let host):
            DocereeLog.debug("App config: invalid URL (environment=\(environment), host=\(host))")
        case .requestEncodingFailed(let error):
            DocereeLog.debug("App config: request encoding failed: \(error.localizedDescription)")
        case .fetchFailed(let error):
            DocereeLog.debug("App config: fetch failed: \(error.localizedDescription)")
        case .refreshed(let config):
            DocereeLog.debug("Fetched Config: \(String(describing: config.data as Any))")
        }
    }

    public static func setApplicationKey(_ key: String) {
        do {
            // Securely archive the string using NSKeyedArchiver
            let data = try NSKeyedArchiver.archivedData(withRootObject: key, requiringSecureCoding: false)
            
            // Write the data to the file URL
            try data.write(to: DocereeAdsIdArchivingUrl, options: .atomic)
            
        } catch {
            DocereeLog.debug("ERROR: \(error.localizedDescription)")
        }
        
        // Load app config
        Task(priority: .userInitiated) {
            await DocereeMobileAds().loadAppConfiguration()
        }
    }

    public func getProfile() -> Hcp? {
        if let profile = UserDefaultsManager.shared.loadLoggedInProfile() {
            return profile
        }
        return loadLegacyArchivedProfile()
    }

    private func loadLegacyArchivedProfile() -> Hcp? {
        do {
            let data = try Data(contentsOf: ProfileArchivingUrl)

            let allowedClasses = NSSet(array: [NSString.self, Hcp.self, NSNumber.self])

            let profile = try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: allowedClasses as! Set<AnyHashable>,
                from: data
            ) as? Hcp

            return profile
        } catch {
            DocereeLog.debug("ERROR: \(error.localizedDescription)")
            return nil
        }
    }
    
    func loadDocereeIdentifier(from url: URL) -> String? {
        do {
            let data = try Data(contentsOf: url)
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) as String?
        } catch {
            if #available(iOS 10.0, *) {
                os_log("Error loading DocereeIdentifier: %@", log: .default, type: .error, error.localizedDescription)
            } else {
                DocereeLog.debug("Error loading DocereeIdentifier: \(error.localizedDescription)")
            }
            return nil
        }
    }

    public class func shared() -> DocereeMobileAds {
        return sharedNetworkManager
    }
    
    public typealias CompletionHandler = ((_ completionStatus:Any?) -> Void)?
    
    public func start(completionHandler: CompletionHandler) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        if #available(iOS 14, *) {
            #if canImport(AdSupport) && canImport(AppTrackingTransparency)
            ATTrackingManager.requestTrackingAuthorization{ (status) in
                switch status {
                case .authorized:
                    DocereeMobileAds.trackingStatus = "authorized"
//                    os_log("authorized", log: .default, type: .error)
                case .denied:
                    DocereeMobileAds.trackingStatus = "denied"
//                    os_log("denied", log: .default, type: .error)
                    return
                case .notDetermined:
                    DocereeMobileAds.trackingStatus = "not determined"
//                    os_log("not determined", log: .default, type: .error)
                    return
                case .restricted:
                    DocereeMobileAds.trackingStatus = "restricted"
//                    os_log("restricted", log: .default, type: .error)
                    return
                @unknown default:
                    DocereeMobileAds.trackingStatus = "Unknown error"
//                    os_log("Unknown error", log: .default, type: .error)
                    return
                }
            }
            #endif
        }
        }
    }
    
    public static func clearUserData() {
        UserDefaultsManager.shared.clearAllPersistedSDKState()
        StorageManager.shared.clearAllAttributeAndSessionData()
        PatientSession.sessionId = nil
        resetStoredUniversalIdsForTesting()
        do {
            try FileManager.default.removeItem(at: ProfileArchivingUrl)
            try FileManager.default.removeItem(at: PlatformArchivingUrl)
            try FileManager.default.removeItem(at: DocereeAdsIdArchivingUrl)
        } catch {}
    }

    internal enum CompletionStatus: Any {
        case Success
        case Failure
        case Loading
    }

//    public func hcpValidationView() -> UIView {
//        let hcpView = HcpValidationView()
//        hcpView.loadData(hcpValidationRequest: HcpValidationRequest())
//        return hcpView
//    }
    
    func omInitialization() {
        
        // Activate the OMID SDK at earliest convenience
        OMIDSessionInteractor.activateOMSDK()

        // Prefetch the OMID JS Library
        // The hosted javascript should be periodically (automatically) updated to the latest version on the hosting server
        // This step might not be needed if the consumed Ads are WebView based with server side OMID injection
        OMIDSessionInteractor.prefetchOMIDSDK()
    }
    
    /// Stores consent for all subsequent ad requests. Non-nil fields merge with any values already stored.
    public func setConsent(_ consent: DocereeConsent) {
        UserDefaultsManager.shared.saveConsent(consent)
    }

    /// Clears all stored consent so the SDK can fall back to IAB keys on the next ad request.
    public func clearConsent() {
        UserDefaultsManager.shared.clearConsent()
    }

    /// Returns stored consent, if any.
    public func consent() -> DocereeConsent? {
        UserDefaultsManager.shared.loadConsent()
    }

    @available(*, deprecated, message: "Use setConsent(_:) with DocereeConsent instead.")
    public func setConsentData(isPersonalizeAd: String = "",
                                privacyComplianceType: String = "",
                                privacyString: String = "") {
        setConsent(
            DocereeConsent(
                userConsent: isPersonalizeAd.isEmpty ? nil : isPersonalizeAd,
                privacyType: privacyComplianceType.isEmpty ? nil : privacyComplianceType,
                privacyString: privacyString.isEmpty ? nil : privacyString
            )
        )
        UserDefaultsManager.shared.setConsentData(
            isPersonalizeAd: isPersonalizeAd,
            privacyComplianceType: privacyComplianceType,
            privacyString: privacyString
        )
    }

    @available(*, deprecated, message: "Use setConsent(_:) with DocereeConsent instead.")
    public func setConsentData(isPersonalizeAd: String,
                                privacyComplianceType: String,
                                privacyComplianceVersion: String,
                                privacyComplianceSID: String,
                                privacyString: String) {
        setConsent(
            DocereeConsent.fromLegacyExplicit(
                isPersonalizeAd: isPersonalizeAd,
                privacyComplianceType: privacyComplianceType,
                privacyComplianceVersion: privacyComplianceVersion,
                privacyComplianceSID: privacyComplianceSID,
                privacyString: privacyString
            )
        )
        UserDefaultsManager.shared.setConsentData(
            isPersonalizeAd: isPersonalizeAd,
            privacyComplianceType: privacyComplianceType,
            privacyComplianceVersion: privacyComplianceVersion,
            privacyComplianceSID: privacyComplianceSID,
            privacyString: privacyString
        )
    }

    /// Universal identifiers for demand matching (RampID, UID2, ID5, LiveIntent). Empty values are omitted from ad requests.
    public func setUniversalIds(rampId: String = "",
                                 uid2: String = "",
                                 id5: String = "",
                                 liveIntentId: String = "") {
        UniversalIdStore.shared.set(
            rampId: rampId,
            uid2: uid2,
            id5: id5,
            liveIntentId: liveIntentId
        )
    }

    /// Clears all stored consent so the SDK can fall back to IAB in-app keys on the next ad request.
    public func clearConsentData() {
        UserDefaultsManager.shared.resetConsentForTesting()
    }
    
}

extension DocereeMobileAds {
    func isHcpExist() -> Bool {
        guard let loggedInUser = self.getProfile() else {
            DocereeLog.debug("Error: Not found profile data")
            return false
        }
        return (loggedInUser.specialization != nil) || (loggedInUser.hcpId != nil)
    }

    internal static func storedUniversalIds() -> UniversalIds {
        UniversalIdStore.shared.current()
    }

    internal static func resetStoredUniversalIdsForTesting() {
        UniversalIdStore.shared.resetForTesting()
    }
}

/// In-memory universal identifier store. Last `setUniversalIds` call wins; values are not persisted by the SDK.
final class UniversalIdStore {
    static let shared = UniversalIdStore()

    private let lock = NSLock()
    private var ids = UniversalIds()

    func set(rampId: String, uid2: String, id5: String, liveIntentId: String) {
        lock.lock()
        defer { lock.unlock() }
        ids = UniversalIds(
            rampId: rampId,
            uid2: uid2,
            id5: id5,
            liveIntentId: liveIntentId
        )
    }

    func current() -> UniversalIds {
        lock.lock()
        defer { lock.unlock() }
        return ids
    }

    func resetForTesting() {
        lock.lock()
        defer { lock.unlock() }
        ids = UniversalIds()
    }
}

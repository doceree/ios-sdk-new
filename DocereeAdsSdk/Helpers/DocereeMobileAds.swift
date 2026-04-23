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
    
    public static func login(with hcp: Hcp) {
        do {
            // Securely archive the Hcp object using NSKeyedArchiver
            let data = try NSKeyedArchiver.archivedData(withRootObject: hcp, requiringSecureCoding: true)
            
            // Write the data to the file URL
            try data.write(to: ProfileArchivingUrl, options: .atomic)

            // OMSDK Initialization
            DocereeMobileAds.shared().omInitialization()

        } catch {
            DocereeLog.debug("ERROR: \(error.localizedDescription)")
        }
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
        do {
            let data = try Data(contentsOf: ProfileArchivingUrl)
            
            // Define allowed classes directly using NSSet to bypass the Hashable issue
            let allowedClasses = NSSet(array: [NSString.self, Hcp.self])
            
            // Use unarchivedObject(ofClasses:) and cast it to Hcp
            let profile = try NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses as! Set<AnyHashable>, from: data) as? Hcp
            
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
    
    // Save consent data
    public func setConsentData(isPersonalizeAd: String = "",
                                privacyComplianceType: String = "",
                                privacyString: String = "") {
        // Persist in UserDefaults
        UserDefaultsManager.shared.setConsentData(
            isPersonalizeAd: isPersonalizeAd,
            privacyComplianceType: privacyComplianceType,
            privacyString: privacyString
        )
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
}

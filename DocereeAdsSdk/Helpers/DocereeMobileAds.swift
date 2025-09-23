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
            print("ERROR: \(error.localizedDescription)")
        }
    }

    func loadAppConfiguration() async {
        do {
            let appId = getBundleIdentifier()
            let config = try await ConfigurationService.shared.fetchAppConfiguration(appId: appId)
            print("Fetched Config:", config?.data as Any)
        } catch {
            print("Error:", error)
        }
    }

    public static func setApplicationKey(_ key: String) {
        do {
            // Securely archive the string using NSKeyedArchiver
            let data = try NSKeyedArchiver.archivedData(withRootObject: key, requiringSecureCoding: false)
            
            // Write the data to the file URL
            try data.write(to: DocereeAdsIdArchivingUrl, options: .atomic)
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
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
            print("ERROR: \(error.localizedDescription)")
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
                print("Error loading DocereeIdentifier: \(error.localizedDescription)")
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
            print("Error: Not found profile data")
            return false
        }
        return (loggedInUser.specialization != nil) || (loggedInUser.hcpId != nil)
    }
}

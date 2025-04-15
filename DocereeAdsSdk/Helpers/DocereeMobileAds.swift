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
            
            // Send the data (assuming DocereeMobileAds is correctly set up)
            DocereeMobileAds.shared().sendData()
            
        } catch {
            print("ERROR: \(error.localizedDescription)")
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

    public func sendData(screenPath: String? = nil, editorialTags: [String]? = nil, gps: String? = nil, rxCodes: [String]? = nil, dxCodes: [String]? = nil, event: [String : String]? = nil) {
        
        if !DocereeMobileAds.collectDataStatus {
            return
        }
           
        let platformData = getPlatformData(rxCodes: rxCodes, dxCodes: dxCodes)
        DocereeAdRequest.shared().sendDataCollection(screenPath: screenPath, editorialTags: editorialTags, gps: gps, platformData: platformData, event: event)
        
    }

//    public func hcpValidationView() -> UIView {
//        let hcpView = HcpValidationView()
//        hcpView.loadData(hcpValidationRequest: HcpValidationRequest())
//        return hcpView
//    }
}


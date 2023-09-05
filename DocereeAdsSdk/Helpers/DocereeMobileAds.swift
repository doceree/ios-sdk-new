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
#endif

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
        NSKeyedArchiver.archiveRootObject(hcp, toFile: ProfileArchivingUrl.path)
        DocereeMobileAds.shared().sendData()
    }
    
    public static func setApplicationKey(_ key: String){
        NSKeyedArchiver.archiveRootObject(key, toFile: DocereeAdsIdArchivingUrl.path)
    }

    public func getProfile() -> Hcp? {
        do {
            let data = try Data(contentsOf: ProfileArchivingUrl)
            if let profile = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Hcp {
//                print(profile)
                return profile
            }
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
        return nil
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

}


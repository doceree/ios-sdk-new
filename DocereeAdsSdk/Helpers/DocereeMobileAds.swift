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
    
    private static var sharedNetworkManager: DocereeMobileAds = {
        var docereeMobileAds = DocereeMobileAds()
        return docereeMobileAds
    }()
    
    public static func login(with hcp: Hcp){
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: hcp, requiringSecureCoding: false)
            try data.write(to: ProfileArchivingUrl)
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
    }
    
    public static func getProfile() -> Hcp? {
        do {
            let data = try Data(contentsOf: ProfileArchivingUrl)
            if let profile = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Hcp {
                print(profile)
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
    
    public func start(completionHandler: CompletionHandler){
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        if #available(iOS 14, *) {
            #if canImport(AdSupport) && canImport(AppTrackingTransparency)
            ATTrackingManager.requestTrackingAuthorization{ (status) in
                switch status{
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
//        }
    }
    
    public static func clearUserData() {
        do {
            try FileManager.default.removeItem(at: ProfileArchivingUrl)
            try FileManager.default.removeItem(at: PlatformArchivingUrl)
        } catch {}
    }
    
    internal enum CompletionStatus: Any {
        case Success
        case Failure
        case Loading
    }
}


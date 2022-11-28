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
    
    public static func login(with hcp: Hcp){
        NSKeyedArchiver.archiveRootObject(hcp, toFile: ProfileArchivingUrl.path)
    }
    
    public static func setApplicationKey(_ key: String){
        NSKeyedArchiver.archiveRootObject(key, toFile: DocereeAdsIdArchivingUrl.path)
//        DocereeMobileAds.shared().sendDefaultData()
    }

    public func getProfile() -> Hcp? {
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
            try FileManager.default.removeItem(at: EventListArchivingUrl)
            try FileManager.default.removeItem(at: EditorialTagsArchivingUrl)
            try FileManager.default.removeItem(at: RxDxCodesArchivingUrl)
        } catch {}
    }
    
    public static func clearEventsData() {
        do {
            try FileManager.default.removeItem(at: EventListArchivingUrl)
        } catch {}
    }
    
    internal enum CompletionStatus: Any {
        case Success
        case Failure
        case Loading
    }
    
//    func sendDefaultData() {
//        DocereeAdRequest.shared().sendDataCollection()
//    }
//
//    public func sendData(rxdxCodes: [String : String]?, editorialTags: [String]?, event: [String : String]?) {
//        if let codes = rxdxCodes {
//            NSKeyedArchiver.archiveRootObject(codes, toFile: RxDxCodesArchivingUrl.path)
//        }
//
//        if let tags = editorialTags {
//            NSKeyedArchiver.archiveRootObject(tags, toFile: EditorialTagsArchivingUrl.path)
//        }
//
//        if !DocereeMobileAds.collectDataStatus {
//            return
//        }
//
//        if let event = event {
//            do {
//                if !FileManager.default.fileExists(atPath: EventListArchivingUrl.path) {
//                    NSKeyedArchiver.archiveRootObject([event], toFile: EventListArchivingUrl.path)
//                } else {
//                    let data = try Data(contentsOf: EventListArchivingUrl)
//                    if var events = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [[String : String]] {
//                        events.append(event)
//                        print(events)
//                        NSKeyedArchiver.archiveRootObject(events, toFile: EventListArchivingUrl.path)
//
//                        if events.count >= 5 {
//                            DocereeAdRequest.shared().sendDataCollection()
//                        }
//                    }
//                }
//            } catch {
//                print("ERROR: \(error.localizedDescription)")
//            }
//        }
//    }
    
    public func getEditorialTags() -> [String]? {
        do {
            let data = try Data(contentsOf: EditorialTagsArchivingUrl)
            if let tags = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] {
                return tags
            }
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
        return nil
    }
    
    public func getEvents() -> [[String : String]]? {
        do {
            let data = try Data(contentsOf: EventListArchivingUrl)
            if let event = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [[String : String]] {
                return event
            }
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
        return nil
    }
    
    public func getCodes() -> [String : String]? {
        do {
            let data = try Data(contentsOf: RxDxCodesArchivingUrl)
            if let codes = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String : String] {
                return codes
            }
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
        return nil
    }
}


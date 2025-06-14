
import UIKit
import AdSupport

func getAdSize(for size: String?) -> AdSize {
    switch size {
    case "320 x 50":
        return Banner()
    case "320 x 100":
        return LargeBanner()
    case "468 x 60":
        return FullBanner()
    case "300 x 250":
        return MediumRectangle()
    case "728 x 90":
        return LeaderBoard()
    case "300 x 50":
        return SmallBanner()
    default:
        return Invalid()
    }
}

func getAdTypeBySize(adSize: AdSize) -> AdType {
    let width: Int = Int(adSize.width)
    let height: Int = Int(adSize.height)
    let dimens: String = "\(width)x\(height)"
    switch dimens {
    case "320x50":
        return AdType.BANNER
    case "300x250":
        return AdType.MEDIUMRECTANGLE
    case "320x100":
        return AdType.LARGEBANNER
    case "468x60":
        return AdType.FULLSIZE
    case "728x90":
        return AdType.LEADERBOARD
    case "300x50":
        return AdType.SMALLBANNER
    default:
        return AdType.INVALID
    }
}

func savePlatformuid(_ newPlatormuid: String) {
    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: newPlatormuid, requiringSecureCoding: false)
        try data.write(to: URL(fileURLWithPath: PlatformArchivingUrl.path), options: .atomic)
    } catch {
        print("Failed to archive object: \(error)")
    }
}

func getIdentifierForAdvertising() -> String? {
    if #available(iOS 14, *) {
        if (DocereeMobileAds.trackingStatus == "authorized") {
            return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        } else {
            return UIDevice.current.identifierForVendor?.uuidString
        }
    } else {
        // Fallback to previous versions
        if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
            return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        } else {
            return UIDevice.current.identifierForVendor?.uuidString
        }
    }
}

func getUUID() async -> String {
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            let id = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device-id"
            continuation.resume(returning: id)
        }
    }
}


func getBundleIdentifier() -> String {
    return Bundle.main.bundleIdentifier ?? "unknown-bundle-id"
}

struct RestEntity {
    private var values: [String: String] = [:]
    
    mutating func add(value: String, forKey key: String){
        values[key] = value
    }
    
    func value(forKey key: String) -> String?{
        return values[key]
    }
    
    func allValues() -> [String: String]{
        return values
    }
    
    func totalItems() -> Int{
        return values.count
    }
}

extension Bundle {
    // Name of the app - title under the icon.
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            object(forInfoDictionaryKey: "CFBundleName") as? String
    }
    
    var releaseVersionNumber: String? {
        return self.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildVersionNumber: String? {
        return self.infoDictionary?["CFBundleVersion"] as? String
    }
}

/// ✅ Checks if the device is an iPad or has a large screen
func isLargeScreen() -> Bool {
    return UIScreen.main.bounds.width > 600
}

var statusBarHeight: CGFloat {
    if #available(iOS 13.0, *) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let statusBarManager = windowScene.statusBarManager {
            return statusBarManager.statusBarFrame.height
        }
        return 0
    } else {
        return UIApplication.shared.statusBarFrame.height
    }
}

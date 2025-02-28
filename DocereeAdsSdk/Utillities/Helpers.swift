
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
    NSKeyedArchiver.archiveRootObject(newPlatormuid, toFile: PlatformArchivingUrl.path)
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


import Foundation
import UIKit

let textFontSize12: CGFloat = 12.0
let textFontSize9: CGFloat = 9.0
let textFontSize10: CGFloat = 10.0
let textFontSize8: CGFloat = 8.0
let sdkVersion = Bundle(for: DocereeAdRequest.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

enum AdType {
    case BANNER
    case FULLSIZE
    case MEDIUMRECTANGLE
    case LEADERBOARD
    case LARGEBANNER
    case SMALLBANNER
    case INVALID
}

enum BlockLevel {
    case AdCoveringContent
    case AdWasInappropriate
    case NotInterestedInCampaign
    case NotInterestedInBrand
    case NotInterestedInBrandType
    case NotInterestedInClientType
    
    var info: (blockLevelCode: String, blockLevelDesc: String) {
        switch self{
        case .AdCoveringContent:
            return ("overlappingAd", "Ad is covering the content of the website.")
        case .AdWasInappropriate:
            return ("inappropriateAd", "Ad was inappropriate.")
        case .NotInterestedInCampaign:
            return ("notInterestedInCampaign", "I'm not interested in seeing ads for this product")
        case .NotInterestedInBrand:
            return ("notInterestedInBrand", "I'm not interested in seeing ads for this brand.")
        case .NotInterestedInBrandType:
            return ("notInterestedInBrandType", "I'm not interested in seeing ads for this category.")
        case .NotInterestedInClientType:
            return ("notInterestedInClientType", "I'm not interested in seeing ads from pharmaceutical brands.")
        }
    }
}

enum Header: String {
    case header_user_agent = "User-Agent"
    case header_advertising_id = "doceree-device-id"
    case is_vendor_id = "is_doceree_iOS_sdk_vendor_id"
    case header_is_ad_tracking_enabled = "is-ad-tracking-enabled"
    case header_app_name = "app-name"
    case header_app_version = "app-version"
    case header_lib_version = "lib-version"
    case header_app_bundle = "app-bundle"
}

enum QueryParamsForGetImage: String {
    case id = "id"
    case size = "size"
    case loggedInUser = "loggedInUser"
    case platformType = "platformType"
    case appKey = "appKey"
}

enum AdBlockService: String {
    case advertiserCampID = "advertiserCampID"
    case publisherACSID = "publisherACSID"
    case blockLevel = "blockLevel"
    case platformUid = "platformUid"
}

enum ConsentType {
    case consentType2
    case consentType3
}

enum EnvironmentType {
    case Dev
    case Prod
    case Local
    case Qa
}

public enum AdPosition {
    case top
    case bottom
    case custom
}

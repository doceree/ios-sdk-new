
import Foundation
import UIKit

let textFontSize12: CGFloat = 12.0
let textFontSize9: CGFloat = 9.0
let textFontSize10: CGFloat = 10.0
let textFontSize8: CGFloat = 8.0
let sdkVersion = Bundle(for: DocereeAdRequest.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
let platformId = 4 // (#1- web #2- mweb #3- andorid #4- ios #5- amp)"
let dataSource = 2 // (#1- js, #2- sdk, #3- adservedata, #4- dmd, #5- purplelab, #6- liveintent)

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

public enum EnvironmentType {
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

enum CollectDataService: String {
    case bundleID = "bnd"
    case platformID = "pl"
    case dataSource = "sr"
    case editorialTags = "mt"
    case event = "el"
    case localTimestamp = "lt"
    case platformData = "pd"
    case partnerData = "qp"
    case advertisingID = "uid"
    case privateMode = "pv"
}

enum Event: String {
    case share = "shr"
    case comment = "cmt"
    case like = "lik"
    case pateintID = "pid"
    case officeID = "oif"
    case providerID = "pro"
    case encounterID = "enc"
    case erxEncounterID = "enx"
    case scrollPath = "scd"
}

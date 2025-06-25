
import Foundation
import UIKit

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

enum HeaderEnum: String {
    case header_user_agent = "User-Agent"
    case header_advertising_id = "doceree-device-id"
    case is_vendor_id = "is_doceree_iOS_sdk_vendor_id"
    case header_is_ad_tracking_enabled = "is-ad-tracking-enabled"
    case header_app_name = "app-name"
    case header_app_version = "app-version"
    case header_lib_version = "lib-version"
    case header_app_bundle = "app-bundle"
    case header_origin = "origin"
    case header_refer = "refer"
}

enum QueryParamsForAdRequest: String {
    case appKey = "appkey"
    case userId = "userid"
    case email = "email"
    case firstName = "firstname"
    case lastName = "lastname"
    case specialization = "specialization"
    case hcpId = "hcpid"
    case hashedHcpId = "hashedhcpid"
    case gender = "gender"
    case city = "city"
    case state = "state"
    case country = "country"
    case zipCode = "zipcode"
    case hashedNPI = "hashedNPI"
    case adUnit = "adunit"
    case br = "br"
    case cdt = "cdt"
    case privacyConsent = "privacyConsent"
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
    case advertisingId = "uid"
    case bundleId = "bnd"
    case platformId = "pl"
    case hcpId = "hcd"
    case dataSource = "sr"
    case screenPath = "pu"
    case editorialTags = "mt"
    case localTimestamp = "lt"
    case installedApps = "ia"
    case privateMode = "pv"
    case gps = "gps"
    case event = "el"
    case platformData = "pd"
    case partnerData = "qp"
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

enum Popup {
    static let title = "Are you a Healthcare Professional?"
    static let description = """
        This content is intended for Healthcare professionals only. By accessing this, you are confirming that you are a healthcare professional. This site may contain promotional information about pharma products.
        """
    static let noButtonText = "No, visit the public website"
    static let yesButtonText = "Yes"
}

struct Constants {
    static let HcpData = "HcpData"
    
    static let vendorKey = "iabtechlab.com-omid"
    
    static let HTMLAdURL = "https://omsdk-demo-files.s3.us-west-2.amazonaws.com/creatives/html_display_creative.html"

    static let HTMLVideoAdURL = "https://omsdk-demo-files.s3.us-west-2.amazonaws.com/creatives/html_video_creative.html"
    
    static let videoAdURL = "https://omsdk-demo-files.s3.us-west-2.amazonaws.com/ra_1.3/IABTL_VAST_Intro_30s.mp4"
    
    static let staticImageAdURL = "https://omsdk-demo-files.s3.us-west-2.amazonaws.com/creative/mania.jpeg"
    
    static var audioAdURL = "https://omsdk-demo-files.s3.us-west-2.amazonaws.com/ra_1.3/IABTechLab_audio_test_file.mp3"

    static var verificationScriptURL = "https://omsdk-public.herokuapp.com/omid-validation-verification-script-v1.js"
    
    static let verificationParameters = ""
}


import Foundation

/// How consent fields were sourced for the outbound ad request.
public enum ConsentSource: String, Equatable {
    case explicit = "explicit"
    case iab = "iab"
}

/// Raw consent signals collected at ad-request time. The SDK forwards values as-is; no parsing or gating on device.
public struct ConsentSignals: Equatable {
    public let isPersonalizeAd: String
    public let privacyComplianceType: String
    public let privacyComplianceVersion: String
    public let privacyComplianceSID: String
    public let privacyString: String
    /// Populated only from IAB TCF `IABTCF_gdprApplies` when consent is sourced from in-app storage.
    public let gdprApplies: String
    public let source: ConsentSource?

    public init(
        isPersonalizeAd: String = "",
        privacyComplianceType: String = "",
        privacyComplianceVersion: String = "",
        privacyComplianceSID: String = "",
        privacyString: String = "",
        gdprApplies: String = "",
        source: ConsentSource? = nil
    ) {
        self.isPersonalizeAd = isPersonalizeAd
        self.privacyComplianceType = privacyComplianceType
        self.privacyComplianceVersion = privacyComplianceVersion
        self.privacyComplianceSID = privacyComplianceSID
        self.privacyString = privacyString
        self.gdprApplies = gdprApplies
        self.source = source
    }
}

/// Universal identity values set via `DocereeMobileAds.setUniversalIds`. Empty values are omitted from the ad request.
public struct UniversalIds: Equatable {
    public let rampId: String
    public let uid2: String
    public let id5: String
    public let liveIntentId: String

    public init(rampId: String = "", uid2: String = "", id5: String = "", liveIntentId: String = "") {
        self.rampId = rampId
        self.uid2 = uid2
        self.id5 = id5
        self.liveIntentId = liveIntentId
    }
}

enum IABConsentStorageKeys {
    static let gppString = "IABGPP_HDR_GppString"
    static let gppSID = "IABGPP_GppSID"
    static let gppVersion = "IABGPP_HDR_Version"
    static let tcfString = "IABTCF_TCString"
    static let tcfPolicyVersion = "IABTCF_PolicyVersion"
    static let gdprApplies = "IABTCF_gdprApplies"
}

import Foundation

/// Collects consent signals for ad requests: explicit publisher values take precedence over IAB in-app storage.
final class ConsentSignalCollector {
    static let shared = ConsentSignalCollector()

    private let defaultsManager: UserDefaultsManager
    private let iabDefaults: UserDefaults

    init(defaultsManager: UserDefaultsManager = .shared, iabDefaults: UserDefaults = .standard) {
        self.defaultsManager = defaultsManager
        self.iabDefaults = iabDefaults
    }

    func collect() -> ConsentSignals {
        if defaultsManager.hasExplicitConsent() {
            let explicit = defaultsManager.getExplicitConsentData()
            return ConsentSignals(
                isPersonalizeAd: explicit.isPersonalizeAd,
                privacyComplianceType: explicit.privacyComplianceType,
                privacyComplianceVersion: explicit.privacyComplianceVersion,
                privacyComplianceSID: explicit.privacyComplianceSID,
                privacyString: explicit.privacyString,
                gdprApplies: "",
                source: .explicit
            )
        }
        return collectFromIAB()
    }

    private func collectFromIAB() -> ConsentSignals {
        let gppString = stringValue(forKey: IABConsentStorageKeys.gppString)
        if !gppString.isEmpty {
            return ConsentSignals(
                isPersonalizeAd: "",
                privacyComplianceType: "gpp",
                privacyComplianceVersion: stringValue(forKey: IABConsentStorageKeys.gppVersion),
                privacyComplianceSID: stringValue(forKey: IABConsentStorageKeys.gppSID),
                privacyString: gppString,
                gdprApplies: "",
                source: .iab
            )
        }

        let tcfString = stringValue(forKey: IABConsentStorageKeys.tcfString)
        if !tcfString.isEmpty {
            return ConsentSignals(
                isPersonalizeAd: "",
                privacyComplianceType: "tcf",
                privacyComplianceVersion: stringValue(forKey: IABConsentStorageKeys.tcfPolicyVersion),
                privacyComplianceSID: "",
                privacyString: tcfString,
                gdprApplies: stringValue(forKey: IABConsentStorageKeys.gdprApplies),
                source: .iab
            )
        }

        return ConsentSignals()
    }

    private func stringValue(forKey key: String) -> String {
        guard let value = iabDefaults.object(forKey: key) else {
            return ""
        }
        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        if let bool = value as? Bool {
            return bool ? "1" : "0"
        }
        return ""
    }
}

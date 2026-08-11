import Foundation

/// Collects consent signals for ad requests: stored consent takes precedence over IAB in-app storage.
final class ConsentSignalCollector {
    static let shared = ConsentSignalCollector()

    private let defaultsManager: UserDefaultsManager
    private let iabDefaults: UserDefaults

    init(defaultsManager: UserDefaultsManager = .shared, iabDefaults: UserDefaults = .standard) {
        self.defaultsManager = defaultsManager
        self.iabDefaults = iabDefaults
    }

    func collect() -> CollectedConsent {
        if let stored = defaultsManager.loadConsent() {
            return CollectedConsent(consent: stored, source: .explicit)
        }

        if defaultsManager.hasExplicitConsent() {
            let legacy = defaultsManager.getExplicitConsentData()
            let consent = DocereeConsent.fromLegacyExplicit(
                isPersonalizeAd: legacy.isPersonalizeAd,
                privacyComplianceType: legacy.privacyComplianceType,
                privacyComplianceVersion: legacy.privacyComplianceVersion,
                privacyComplianceSID: legacy.privacyComplianceSID,
                privacyString: legacy.privacyString
            )
            return CollectedConsent(consent: consent, source: .explicit)
        }

        return collectFromIAB()
    }

    /// Backward-compatible accessor used by older tests and call sites.
    func collectLegacySignals() -> ConsentSignals {
        let collected = collect()
        let consent = collected.consent
        return ConsentSignals(
            isPersonalizeAd: consent.userConsent ?? "",
            privacyComplianceType: consent.privacyType ?? "",
            privacyComplianceVersion: consent.privacyVersion ?? "",
            privacyComplianceSID: legacySidString(from: consent, source: collected.source),
            privacyString: consent.privacyString ?? "",
            gdprApplies: collected.gdprApplies,
            source: collected.source
        )
    }

    private func legacySidString(from consent: DocereeConsent, source: ConsentSource?) -> String {
        guard let privacySid = consent.privacySid, !privacySid.isEmpty else { return "" }
        if source == .iab && consent.privacyType == "gpp" {
            return privacySid.joined(separator: "_")
        }
        return privacySid.joined(separator: ",")
    }

    private func collectFromIAB() -> CollectedConsent {
        let gppString = stringValue(forKey: IABConsentStorageKeys.gppString)
        if !gppString.isEmpty {
            return CollectedConsent(
                consent: DocereeConsent(
                    privacyType: "gpp",
                    privacyString: gppString,
                    privacySid: DocereeConsent.parseSidList(stringValue(forKey: IABConsentStorageKeys.gppSID)),
                    privacyVersion: nonEmpty(stringValue(forKey: IABConsentStorageKeys.gppVersion))
                ),
                source: .iab
            )
        }

        let tcfString = stringValue(forKey: IABConsentStorageKeys.tcfString)
        if !tcfString.isEmpty {
            return CollectedConsent(
                consent: DocereeConsent(
                    privacyType: "tcf",
                    privacyString: tcfString,
                    privacyVersion: nonEmpty(stringValue(forKey: IABConsentStorageKeys.tcfPolicyVersion))
                ),
                source: .iab,
                gdprApplies: stringValue(forKey: IABConsentStorageKeys.gdprApplies)
            )
        }

        return CollectedConsent(consent: DocereeConsent())
    }

    private func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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

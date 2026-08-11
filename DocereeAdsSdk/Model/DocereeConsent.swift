import Foundation

/// Unified consent for privacy frameworks (TCF, GPP) and publisher-attested metadata.
/// One consent applies to all ad requests regardless of logged-in user type.
public struct DocereeConsent: Equatable, Codable, Sendable {
    public let userConsent: String?
    public let privacyType: String?
    public let privacyString: String?
    public let privacySid: [String]?
    public let privacyVersion: String?
    public let consentBasis: String?
    public let mechanism: String?
    public let grantedAt: String?
    public let expiresAt: String?
    public let consentReferenceId: String?

    public init(
        userConsent: String? = nil,
        privacyType: String? = nil,
        privacyString: String? = nil,
        privacySid: [String]? = nil,
        privacyVersion: String? = nil,
        consentBasis: String? = nil,
        mechanism: String? = nil,
        grantedAt: String? = nil,
        expiresAt: String? = nil,
        consentReferenceId: String? = nil
    ) {
        self.userConsent = userConsent
        self.privacyType = privacyType
        self.privacyString = privacyString
        self.privacySid = privacySid
        self.privacyVersion = privacyVersion
        self.consentBasis = consentBasis
        self.mechanism = mechanism
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
        self.consentReferenceId = consentReferenceId
    }

    var isEmpty: Bool {
        cnsPayloadFields().isEmpty
    }

    /// Merges non-nil fields from `incoming` into the stored consent shape.
    func merging(_ incoming: DocereeConsent) -> DocereeConsent {
        DocereeConsent(
            userConsent: incoming.userConsent ?? userConsent,
            privacyType: incoming.privacyType ?? privacyType,
            privacyString: incoming.privacyString ?? privacyString,
            privacySid: incoming.privacySid ?? privacySid,
            privacyVersion: incoming.privacyVersion ?? privacyVersion,
            consentBasis: incoming.consentBasis ?? consentBasis,
            mechanism: incoming.mechanism ?? mechanism,
            grantedAt: incoming.grantedAt ?? grantedAt,
            expiresAt: incoming.expiresAt ?? expiresAt,
            consentReferenceId: incoming.consentReferenceId ?? consentReferenceId
        )
    }

    static func fromLegacyExplicit(
        isPersonalizeAd: String,
        privacyComplianceType: String,
        privacyComplianceVersion: String,
        privacyComplianceSID: String,
        privacyString: String
    ) -> DocereeConsent {
        DocereeConsent(
            userConsent: nonEmpty(isPersonalizeAd),
            privacyType: nonEmpty(privacyComplianceType),
            privacyString: nonEmpty(privacyString),
            privacySid: parseSidList(privacyComplianceSID),
            privacyVersion: nonEmpty(privacyComplianceVersion)
        )
    }

    static func parseSidList(_ value: String) -> [String]? {
        let sectionIDs = value
            .split(whereSeparator: { $0 == "," || $0 == "_" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return sectionIDs.isEmpty ? nil : sectionIDs
    }

    func cnsPayloadFields(source: ConsentSource? = nil, gdprApplies: String? = nil) -> [String: Any] {
        var cns: [String: Any] = [:]

        addNonEmpty(userConsent, forKey: .userPreference, into: &cns)
        addNonEmpty(privacyType, forKey: .privacyType, into: &cns)
        addNonEmpty(privacyString, forKey: .privacyString, into: &cns)

        if let version = privacyVersion?.trimmingCharacters(in: .whitespacesAndNewlines),
           !version.isEmpty,
           Self.isValidPrivacyVersion(version) {
            cns[ConsentPayloadKey.privacyVersion.rawValue] = version
        }

        if let privacySid, !privacySid.isEmpty {
            cns[ConsentPayloadKey.privacySectionIDs.rawValue] = privacySid
        }

        addNonEmpty(consentBasis, forKey: .consentBasis, into: &cns)
        addNonEmpty(mechanism, forKey: .mechanism, into: &cns)
        addNonEmpty(grantedAt, forKey: .grantedAt, into: &cns)
        addNonEmpty(expiresAt, forKey: .expiresAt, into: &cns)
        addNonEmpty(consentReferenceId, forKey: .consentReferenceId, into: &cns)

        if let gdprApplies = gdprApplies?.trimmingCharacters(in: .whitespacesAndNewlines),
           !gdprApplies.isEmpty,
           let intValue = Int(gdprApplies),
           intValue == 0 || intValue == 1 {
            cns[ConsentPayloadKey.gdprApplies.rawValue] = intValue
        }

        if let source {
            cns[ConsentPayloadKey.consentSource.rawValue] = source.rawValue
        }

        return cns
    }

    private static func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func isValidPrivacyVersion(_ value: String) -> Bool {
        Double(value) != nil
    }

    private func addNonEmpty(_ value: String?, forKey key: ConsentPayloadKey, into object: inout [String: Any]) {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return }
        object[key.rawValue] = trimmed
    }

    private func addNonEmpty(_ value: String?, forKey key: PublisherAttestedConsentKey, into object: inout [String: Any]) {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return }
        object[key.rawValue] = trimmed
    }
}

/// Consent resolved at ad-request time, including IAB-only metadata.
struct CollectedConsent: Equatable {
    let consent: DocereeConsent
    let source: ConsentSource?
    let gdprApplies: String

    init(consent: DocereeConsent, source: ConsentSource? = nil, gdprApplies: String = "") {
        self.consent = consent
        self.source = source
        self.gdprApplies = gdprApplies
    }

    func makeCnsObject() -> [String: Any]? {
        let payload = consent.cnsPayloadFields(
            source: source,
            gdprApplies: gdprApplies.isEmpty ? nil : gdprApplies
        )
        return payload.isEmpty ? nil : payload
    }
}

/// Builds unified consent for `DocereeMobileAds.shared().setConsent(_:)`.
public final class DocereeConsentBuilder {

    private var userConsent: String?
    private var privacyType: String?
    private var privacyString: String?
    private var privacySid: [String]?
    private var privacyVersion: String?
    private var consentBasis: String?
    private var mechanism: String?
    private var grantedAt: String?
    private var expiresAt: String?
    private var consentReferenceId: String?

    public init() {}

    public func setUserConsent(_ userConsent: String?) -> DocereeConsentBuilder {
        self.userConsent = userConsent
        return self
    }

    public func setPrivacyType(_ privacyType: String?) -> DocereeConsentBuilder {
        self.privacyType = privacyType
        return self
    }

    public func setPrivacyString(_ privacyString: String?) -> DocereeConsentBuilder {
        self.privacyString = privacyString
        return self
    }

    public func setPrivacySid(_ privacySid: [String]?) -> DocereeConsentBuilder {
        self.privacySid = privacySid
        return self
    }

    /// Accepts comma- or underscore-separated section IDs (e.g. `"2,6"` or `"2_6"`).
    public func setPrivacySid(_ commaSeparated: String?) -> DocereeConsentBuilder {
        guard let commaSeparated else {
            privacySid = nil
            return self
        }
        privacySid = DocereeConsent.parseSidList(commaSeparated)
        return self
    }

    public func setPrivacyVersion(_ privacyVersion: String?) -> DocereeConsentBuilder {
        self.privacyVersion = privacyVersion
        return self
    }

    public func setConsentBasis(_ consentBasis: String?) -> DocereeConsentBuilder {
        self.consentBasis = consentBasis
        return self
    }

    public func setMechanism(_ mechanism: String?) -> DocereeConsentBuilder {
        self.mechanism = mechanism
        return self
    }

    public func setGrantedAt(_ grantedAt: String?) -> DocereeConsentBuilder {
        self.grantedAt = grantedAt
        return self
    }

    public func setExpiresAt(_ expiresAt: String?) -> DocereeConsentBuilder {
        self.expiresAt = expiresAt
        return self
    }

    public func setConsentReferenceId(_ consentReferenceId: String?) -> DocereeConsentBuilder {
        self.consentReferenceId = consentReferenceId
        return self
    }

    public func build() -> DocereeConsent {
        DocereeConsent(
            userConsent: userConsent,
            privacyType: privacyType,
            privacyString: privacyString,
            privacySid: privacySid,
            privacyVersion: privacyVersion,
            consentBasis: consentBasis,
            mechanism: mechanism,
            grantedAt: grantedAt,
            expiresAt: expiresAt,
            consentReferenceId: consentReferenceId
        )
    }
}

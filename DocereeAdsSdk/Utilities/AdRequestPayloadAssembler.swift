import Foundation

/// Builds the outbound ad-request JSON body, omitting empty consent and identity fields.
enum AdRequestPayloadAssembler {
    static func makeBody(
        appKey: String,
        userId: String,
        user: Hcp,
        adUnitId: String,
        consent: ConsentSignals,
        universalIds: UniversalIds,
        br: String
    ) -> [String: Any] {
        var body: [String: Any] = [
            QueryParamsForAdRequest.appKey.rawValue: appKey,
            QueryParamsForAdRequest.userId.rawValue: userId,
            QueryParamsForAdRequest.email.rawValue: user.email ?? "",
            QueryParamsForAdRequest.firstName.rawValue: user.firstName ?? "",
            QueryParamsForAdRequest.lastName.rawValue: user.lastName ?? "",
            QueryParamsForAdRequest.specialization.rawValue: user.specialization ?? "",
            QueryParamsForAdRequest.hcpId.rawValue: user.hcpId ?? "",
            QueryParamsForAdRequest.hashedHcpId.rawValue: user.hashedHcpId ?? "",
            QueryParamsForAdRequest.gender.rawValue: user.gender ?? "",
            QueryParamsForAdRequest.city.rawValue: user.city ?? "",
            QueryParamsForAdRequest.state.rawValue: user.state ?? "",
            QueryParamsForAdRequest.country.rawValue: user.country ?? "",
            QueryParamsForAdRequest.zipCode.rawValue: user.zipCode ?? "",
            QueryParamsForAdRequest.adUnit.rawValue: adUnitId,
            QueryParamsForAdRequest.br.rawValue: br,
            QueryParamsForAdRequest.cdt.rawValue: "",
            QueryParamsForAdRequest.privacyConsent.rawValue: 1
        ]

        if let consentObject = makeConsentObject(from: consent) {
            body[QueryParamsForAdRequest.consent.rawValue] = consentObject
        }

        addNonEmptyString(universalIds.rampId, forKey: QueryParamsForAdRequest.rampId, into: &body)
        addNonEmptyString(universalIds.uid2, forKey: QueryParamsForAdRequest.uid2, into: &body)
        addNonEmptyString(universalIds.id5, forKey: QueryParamsForAdRequest.id5, into: &body)
        addNonEmptyString(universalIds.liveIntentId, forKey: QueryParamsForAdRequest.liveIntentId, into: &body)

        return body
    }

    static func makeConsentObject(from consent: ConsentSignals) -> [String: Any]? {
        var cns: [String: Any] = [:]

        addNonEmptyString(consent.isPersonalizeAd, forKey: .userPreference, into: &cns)
        addNonEmptyString(consent.privacyComplianceType, forKey: .privacyType, into: &cns)
        addNonEmptyString(consent.privacyString, forKey: .privacyString, into: &cns)

        if let version = parsePrivacyVersion(consent.privacyComplianceVersion) {
            cns[ConsentPayloadKey.privacyVersion.rawValue] = version
        }

        if let sectionIDs = parseSectionIDs(
            consent.privacyComplianceSID,
            source: consent.source,
            privacyType: consent.privacyComplianceType
        ) {
            cns[ConsentPayloadKey.privacySectionIDs.rawValue] = sectionIDs
        }

        if let gdprApplies = parseGdprApplies(consent.gdprApplies) {
            cns[ConsentPayloadKey.gdprApplies.rawValue] = gdprApplies
        }

        if let source = consent.source?.rawValue {
            cns[ConsentPayloadKey.consentSource.rawValue] = source
        }

        return cns.isEmpty ? nil : cns
    }

    private static func parseGdprApplies(_ value: String) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let intValue = Int(trimmed), intValue == 0 || intValue == 1 else { return nil }
        return intValue
    }

    private static func parsePrivacyVersion(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private static func parseSectionIDs(
        _ value: String,
        source: ConsentSource?,
        privacyType: String
    ) -> [String]? {
        let delimiter: Character = (source == .iab && privacyType == "gpp") ? "_" : ","
        let sectionIDs = value
            .split(separator: delimiter)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return sectionIDs.isEmpty ? nil : sectionIDs
    }

    private static func addNonEmptyString(_ value: String, forKey key: ConsentPayloadKey, into object: inout [String: Any]) {
        guard !value.isEmpty else { return }
        object[key.rawValue] = value
    }

    private static func addNonEmptyString(_ value: String, forKey key: QueryParamsForAdRequest, into body: inout [String: Any]) {
        guard !value.isEmpty else { return }
        body[key.rawValue] = value
    }
}

import Foundation

/// Builds the outbound ad-request JSON body, omitting empty consent and identity fields.
enum AdRequestPayloadAssembler {
    static func makeBody(
        appKey: String,
        userId: String,
        user: Hcp,
        adUnitId: String,
        consent: CollectedConsent,
        universalIds: UniversalIds,
        br: String,
        ptd: String = "",
        atd: String = "",
        role: DocereeUserRole? = nil
    ) -> [String: Any] {
        let resolvedRole = role ?? UserDefaultsManager.shared.loggedInUserRole() ?? user.role
        switch resolvedRole {
        case .ha:
            return makeHealthAssociateBody(
                appKey: appKey,
                userId: userId,
                user: user,
                adUnitId: adUnitId,
                consent: consent,
                universalIds: universalIds,
                br: br,
                ptd: ptd,
                atd: atd,
                role: resolvedRole
            )
        case .user:
            return makeUserBody(
                appKey: appKey,
                userId: userId,
                user: user,
                adUnitId: adUnitId,
                consent: consent,
                universalIds: universalIds,
                br: br,
                ptd: ptd,
                atd: atd,
                role: resolvedRole
            )
        case .hcp:
            return makeHcpBody(
                appKey: appKey,
                userId: userId,
                user: user,
                adUnitId: adUnitId,
                consent: consent,
                universalIds: universalIds,
                br: br,
                ptd: ptd,
                atd: atd,
                role: resolvedRole
            )
        }
    }

    private static func makeHcpBody(
        appKey: String,
        userId: String,
        user: Hcp,
        adUnitId: String,
        consent: CollectedConsent,
        universalIds: UniversalIds,
        br: String,
        ptd: String,
        atd: String,
        role: DocereeUserRole
    ) -> [String: Any] {
        var body: [String: Any] = [
            QueryParamsForAdRequest.appKey.rawValue: appKey,
            QueryParamsForAdRequest.userId.rawValue: userId,
            QueryParamsForAdRequest.role.rawValue: role.rawValue,
            QueryParamsForAdRequest.email.rawValue: user.email ?? "",
            QueryParamsForAdRequest.firstName.rawValue: user.firstName ?? "",
            QueryParamsForAdRequest.lastName.rawValue: user.lastName ?? "",
            QueryParamsForAdRequest.mobile.rawValue: user.mobile ?? "",
            QueryParamsForAdRequest.dateOfBirth.rawValue: user.dateOfBirth ?? "",
            QueryParamsForAdRequest.specialization.rawValue: user.specialization ?? "",
            QueryParamsForAdRequest.organisation.rawValue: user.organisation ?? "",
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

        addDataAttributes(ptd: ptd, atd: atd, into: &body)

        addNonEmptyString(user.hashedEmail ?? "", forKey: QueryParamsForAdRequest.hashedEmail, into: &body)
        addNonEmptyString(user.hashedMobile ?? "", forKey: QueryParamsForAdRequest.hashedMobile, into: &body)

        if let consentObject = consent.makeCnsObject() {
            body[QueryParamsForAdRequest.consent.rawValue] = consentObject
        }

        addNonEmptyString(universalIds.rampId, forKey: QueryParamsForAdRequest.rampId, into: &body)
        addNonEmptyString(universalIds.uid2, forKey: QueryParamsForAdRequest.uid2, into: &body)
        addNonEmptyString(universalIds.id5, forKey: QueryParamsForAdRequest.id5, into: &body)
        addNonEmptyString(universalIds.liveIntentId, forKey: QueryParamsForAdRequest.liveIntentId, into: &body)

        return body
    }

    /// Health Associate payload — used when profile role is `.ha` (e.g. Home screen login).
    private static func makeHealthAssociateBody(
        appKey: String,
        userId: String,
        user: Hcp,
        adUnitId: String,
        consent: CollectedConsent,
        universalIds: UniversalIds,
        br: String,
        ptd: String,
        atd: String,
        role: DocereeUserRole
    ) -> [String: Any] {
        var body: [String: Any] = [
            QueryParamsForAdRequest.appKey.rawValue: appKey,
            QueryParamsForAdRequest.userId.rawValue: userId,
            QueryParamsForAdRequest.role.rawValue: role.rawValue,
            QueryParamsForAdRequest.email.rawValue: user.email ?? "",
            QueryParamsForAdRequest.firstName.rawValue: user.firstName ?? "",
            QueryParamsForAdRequest.lastName.rawValue: user.lastName ?? "",
            QueryParamsForAdRequest.mobile.rawValue: user.mobile ?? "",
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

        addDataAttributes(ptd: ptd, atd: atd, into: &body)

        addNonEmptyString(user.hashedEmail ?? "", forKey: QueryParamsForAdRequest.hashedEmail, into: &body)
        addNonEmptyString(user.hashedMobile ?? "", forKey: QueryParamsForAdRequest.hashedMobile, into: &body)
        addNonEmptyString(user.dateOfBirth ?? "", forKey: QueryParamsForAdRequest.dateOfBirth, into: &body)
        addNonEmptyString(user.associateId ?? "", forKey: QueryParamsForAdRequest.associateId, into: &body)
        addNonEmptyString(user.hashedAssociateId ?? "", forKey: QueryParamsForAdRequest.hashedAssociateId, into: &body)
        addNonEmptyString(user.associateRole ?? "", forKey: QueryParamsForAdRequest.associateRole, into: &body)
        addNonEmptyString(user.department ?? "", forKey: QueryParamsForAdRequest.department, into: &body)
        addNonEmptyString(user.organisation ?? "", forKey: QueryParamsForAdRequest.organisation, into: &body)
        if let clinicalInfluenceTier = user.clinicalInfluenceTier {
            body[QueryParamsForAdRequest.clinicalInfluenceTier.rawValue] = clinicalInfluenceTier
        }

        if let consentObject = consent.makeCnsObject() {
            body[QueryParamsForAdRequest.consent.rawValue] = consentObject
        }

        addNonEmptyString(universalIds.rampId, forKey: QueryParamsForAdRequest.rampId, into: &body)
        addNonEmptyString(universalIds.uid2, forKey: QueryParamsForAdRequest.uid2, into: &body)
        addNonEmptyString(universalIds.id5, forKey: QueryParamsForAdRequest.id5, into: &body)
        addNonEmptyString(universalIds.liveIntentId, forKey: QueryParamsForAdRequest.liveIntentId, into: &body)

        return body
    }

    /// User payload — used when profile role is `.user`.
    private static func makeUserBody(
        appKey: String,
        userId: String,
        user: Hcp,
        adUnitId: String,
        consent: CollectedConsent,
        universalIds: UniversalIds,
        br: String,
        ptd: String,
        atd: String,
        role: DocereeUserRole
    ) -> [String: Any] {
        var body: [String: Any] = [
            QueryParamsForAdRequest.appKey.rawValue: appKey,
            QueryParamsForAdRequest.userId.rawValue: userId,
            QueryParamsForAdRequest.role.rawValue: role.rawValue,
            QueryParamsForAdRequest.email.rawValue: user.email ?? "",
            QueryParamsForAdRequest.firstName.rawValue: user.firstName ?? "",
            QueryParamsForAdRequest.lastName.rawValue: user.lastName ?? "",
            QueryParamsForAdRequest.mobile.rawValue: user.mobile ?? "",
            QueryParamsForAdRequest.specialization.rawValue: user.specialization ?? "",
            QueryParamsForAdRequest.organisation.rawValue: user.organisation ?? "",
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

        addDataAttributes(ptd: ptd, atd: atd, into: &body)

        addNonEmptyString(user.userType ?? "", forKey: QueryParamsForAdRequest.userType, into: &body)
        addNonEmptyString(user.hashedEmail ?? "", forKey: QueryParamsForAdRequest.hashedEmail, into: &body)
        addNonEmptyString(user.hashedMobile ?? "", forKey: QueryParamsForAdRequest.hashedMobile, into: &body)
        addNonEmptyString(user.dateOfBirth ?? "", forKey: QueryParamsForAdRequest.dateOfBirth, into: &body)

        if let consentObject = consent.makeCnsObject() {
            body[QueryParamsForAdRequest.consent.rawValue] = consentObject
        }

        addNonEmptyString(universalIds.rampId, forKey: QueryParamsForAdRequest.rampId, into: &body)
        addNonEmptyString(universalIds.uid2, forKey: QueryParamsForAdRequest.uid2, into: &body)
        addNonEmptyString(universalIds.id5, forKey: QueryParamsForAdRequest.id5, into: &body)
        addNonEmptyString(universalIds.liveIntentId, forKey: QueryParamsForAdRequest.liveIntentId, into: &body)

        return body
    }

    static func makeConsentObject(from consent: CollectedConsent) -> [String: Any]? {
        consent.makeCnsObject()
    }

    static func makeConsentObject(from consent: ConsentSignals) -> [String: Any]? {
        let collected = CollectedConsent(
            consent: DocereeConsent(
                userConsent: nonEmpty(consent.isPersonalizeAd),
                privacyType: nonEmpty(consent.privacyComplianceType),
                privacyString: nonEmpty(consent.privacyString),
                privacySid: DocereeConsent.parseSidList(consent.privacyComplianceSID),
                privacyVersion: nonEmpty(consent.privacyComplianceVersion)
            ),
            source: consent.source,
            gdprApplies: consent.gdprApplies
        )
        return collected.makeCnsObject()
    }

    private static func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func parseGdprApplies(_ value: String) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let intValue = Int(trimmed), intValue == 0 || intValue == 1 else { return nil }
        return intValue
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

    private static func addDataAttributes(
        ptd: String,
        atd: String,
        into body: inout [String: Any]
    ) {
        addNonEmptyString(ptd, forKey: QueryParamsForAdRequest.ptd, into: &body)
        addNonEmptyString(atd, forKey: QueryParamsForAdRequest.atd, into: &body)
    }
}

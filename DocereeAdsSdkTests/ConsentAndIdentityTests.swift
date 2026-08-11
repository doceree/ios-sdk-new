import XCTest
@testable import DocereeAdsSdk

final class ConsentAndIdentityTests: XCTestCase {

    private var consentDefaults: UserDefaults!
    private var iabDefaults: UserDefaults!
    private var defaultsManager: UserDefaultsManager!

    override func setUp() {
        super.setUp()
        consentDefaults = UserDefaults(suiteName: "ConsentAndIdentityTests.consent.\(UUID().uuidString)")!
        iabDefaults = UserDefaults(suiteName: "ConsentAndIdentityTests.iab.\(UUID().uuidString)")!
        defaultsManager = UserDefaultsManager(defaults: consentDefaults)
        defaultsManager.resetConsentForTesting()
        clearIABDefaults()
        DocereeMobileAds.resetStoredUniversalIdsForTesting()
    }

    override func tearDown() {
        defaultsManager.resetConsentForTesting()
        clearIABDefaults()
        DocereeMobileAds.resetStoredUniversalIdsForTesting()
        consentDefaults = nil
        iabDefaults = nil
        defaultsManager = nil
        super.tearDown()
    }

    func testLegacySetConsentDataForwardsExplicitSource() {
        defaultsManager.setConsentData(
            isPersonalizeAd: "1",
            privacyComplianceType: "GDPR",
            privacyString: "legacy-tc"
        )

        let signals = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collectLegacySignals()
        XCTAssertEqual(signals.isPersonalizeAd, "1")
        XCTAssertEqual(signals.privacyComplianceType, "GDPR")
        XCTAssertEqual(signals.privacyString, "legacy-tc")
        XCTAssertEqual(signals.privacyComplianceVersion, "")
        XCTAssertEqual(signals.privacyComplianceSID, "")
        XCTAssertEqual(signals.source, .explicit)
    }

    func testExtendedSetConsentDataForwardsAllFields() {
        defaultsManager.setConsentData(
            isPersonalizeAd: "0",
            privacyComplianceType: "gpp",
            privacyComplianceVersion: "1.1",
            privacyComplianceSID: "2,6",
            privacyString: "GPP_STRING"
        )

        let signals = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collectLegacySignals()
        XCTAssertEqual(signals.privacyComplianceVersion, "1.1")
        XCTAssertEqual(signals.privacyComplianceSID, "2,6")
        XCTAssertEqual(signals.privacyString, "GPP_STRING")
        XCTAssertEqual(signals.source, .explicit)
    }

    func testExplicitConsentTakesPrecedenceOverIAB() {
        defaultsManager.setConsentData(
            isPersonalizeAd: "1",
            privacyComplianceType: "tcf",
            privacyComplianceVersion: "",
            privacyComplianceSID: "",
            privacyString: "explicit"
        )
        iabDefaults.set("iab-gpp", forKey: IABConsentStorageKeys.gppString)
        iabDefaults.set("7", forKey: IABConsentStorageKeys.gppSID)

        let signals = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collectLegacySignals()
        XCTAssertEqual(signals.privacyString, "explicit")
        XCTAssertEqual(signals.source, .explicit)
    }

    func testIABGPPFallbackWhenNoExplicitConsent() {
        iabDefaults.set("DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA", forKey: IABConsentStorageKeys.gppString)
        iabDefaults.set("2_6", forKey: IABConsentStorageKeys.gppSID)
        iabDefaults.set("1.1", forKey: IABConsentStorageKeys.gppVersion)

        let signals = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collectLegacySignals()
        XCTAssertEqual(signals.privacyComplianceType, "gpp")
        XCTAssertEqual(signals.privacyString, "DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA")
        XCTAssertEqual(signals.privacyComplianceSID, "2_6")
        XCTAssertEqual(signals.privacyComplianceVersion, "1.1")
        XCTAssertEqual(signals.source, .iab)
    }

    func testIABTCFFallbackWhenNoExplicitConsent() {
        iabDefaults.set("COwguNiOwguNiADABBENB-CgAAAAAAAAAAYgAAAAAAAA", forKey: IABConsentStorageKeys.tcfString)
        iabDefaults.set(4, forKey: IABConsentStorageKeys.tcfPolicyVersion)
        iabDefaults.set(1, forKey: IABConsentStorageKeys.gdprApplies)

        let signals = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collectLegacySignals()
        XCTAssertEqual(signals.privacyComplianceType, "tcf")
        XCTAssertEqual(signals.privacyString, "COwguNiOwguNiADABBENB-CgAAAAAAAAAAYgAAAAAAAA")
        XCTAssertEqual(signals.privacyComplianceVersion, "4")
        XCTAssertEqual(signals.privacyComplianceSID, "")
        XCTAssertEqual(signals.gdprApplies, "1")
        XCTAssertEqual(signals.source, .iab)
    }

    func testIABGPPFallbackTakesPrecedenceOverTCF() {
        iabDefaults.set("GPP_STRING", forKey: IABConsentStorageKeys.gppString)
        iabDefaults.set("2_7", forKey: IABConsentStorageKeys.gppSID)
        iabDefaults.set("COwguNiOwguNiADABBENB-CgAAAAAAAAAAYgAAAAAAAA", forKey: IABConsentStorageKeys.tcfString)

        let signals = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collectLegacySignals()
        XCTAssertEqual(signals.privacyComplianceType, "gpp")
        XCTAssertEqual(signals.privacyString, "GPP_STRING")
        XCTAssertEqual(signals.privacyComplianceSID, "2_7")
    }

    func testMissingIABKeysReturnsNoConsentSource() {
        let signals = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collectLegacySignals()
        XCTAssertNil(signals.source)
        XCTAssertEqual(signals.privacyString, "")
    }

    func testUniversalIdsOverwriteAndOmitEmptyValues() {
        DocereeMobileAds.shared().setUniversalIds(rampId: "ramp-1", uid2: "uid2-1")
        DocereeMobileAds.shared().setUniversalIds(rampId: "ramp-2", uid2: "", id5: "id5-2")

        let ids = DocereeMobileAds.storedUniversalIds()
        XCTAssertEqual(ids.rampId, "ramp-2")
        XCTAssertEqual(ids.uid2, "")
        XCTAssertEqual(ids.id5, "id5-2")

        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: HcpBuilder().build(),
            adUnitId: "unit",
            consent: CollectedConsent(consent: DocereeConsent()),
            universalIds: ids,
            br: ""
        )
        XCTAssertEqual(body[QueryParamsForAdRequest.rampId.rawValue] as? String, "ramp-2")
        XCTAssertEqual(body[QueryParamsForAdRequest.id5.rawValue] as? String, "id5-2")
        XCTAssertNil(body[QueryParamsForAdRequest.uid2.rawValue])
        XCTAssertNil(body[QueryParamsForAdRequest.liveIntentId.rawValue])
    }

    func testAdRequestBodyOmitsEmptyConsentFields() {
        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: HcpBuilder().build(),
            adUnitId: "unit",
            consent: CollectedConsent(
                consent: DocereeConsent(userConsent: "1"),
                source: .explicit
            ),
            universalIds: UniversalIds(),
            br: ""
        )

        let cns = body[QueryParamsForAdRequest.consent.rawValue] as? [String: Any]
        XCTAssertEqual(cns?[ConsentPayloadKey.userPreference.rawValue] as? String, "1")
        XCTAssertEqual(cns?[ConsentPayloadKey.consentSource.rawValue] as? String, "explicit")
        XCTAssertNil(cns?[ConsentPayloadKey.privacyType.rawValue])
        XCTAssertNil(cns?[ConsentPayloadKey.privacyVersion.rawValue])
        XCTAssertNil(cns?[ConsentPayloadKey.privacySectionIDs.rawValue])
    }

    func testIABGPPFallbackForwardsToCnsBody() {
        iabDefaults.set("DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA", forKey: IABConsentStorageKeys.gppString)
        iabDefaults.set("2_6", forKey: IABConsentStorageKeys.gppSID)
        iabDefaults.set("1.1", forKey: IABConsentStorageKeys.gppVersion)

        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: HcpBuilder().build(),
            adUnitId: "unit",
            consent: ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collect(),
            universalIds: UniversalIds(),
            br: ""
        )

        let cns = body[QueryParamsForAdRequest.consent.rawValue] as? [String: Any]
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyType.rawValue] as? String, "gpp")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyString.rawValue] as? String, "DBABMA~CPXxRfAPXxRfAAfKABENB-CgAAAAAAAAAAYgAAAAAAAA")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacySectionIDs.rawValue] as? [String], ["2", "6"])
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyVersion.rawValue] as? String, "1.1")
        XCTAssertEqual(cns?[ConsentPayloadKey.consentSource.rawValue] as? String, "iab")
        XCTAssertNil(cns?[ConsentPayloadKey.gdprApplies.rawValue])
    }

    func testIABTCFFallbackForwardsGdprAppliesToCnsBody() {
        iabDefaults.set("COwguNiOwguNiADABBENB-CgAAAAAAAAAAYgAAAAAAAA", forKey: IABConsentStorageKeys.tcfString)
        iabDefaults.set(4, forKey: IABConsentStorageKeys.tcfPolicyVersion)
        iabDefaults.set(1, forKey: IABConsentStorageKeys.gdprApplies)

        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: HcpBuilder().build(),
            adUnitId: "unit",
            consent: ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collect(),
            universalIds: UniversalIds(),
            br: ""
        )

        let cns = body[QueryParamsForAdRequest.consent.rawValue] as? [String: Any]
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyType.rawValue] as? String, "tcf")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyString.rawValue] as? String, "COwguNiOwguNiADABBENB-CgAAAAAAAAAAYgAAAAAAAA")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyVersion.rawValue] as? String, "4")
        XCTAssertNil(cns?[ConsentPayloadKey.privacySectionIDs.rawValue])
        XCTAssertEqual(cns?[ConsentPayloadKey.gdprApplies.rawValue] as? Int, 1)
        XCTAssertEqual(cns?[ConsentPayloadKey.consentSource.rawValue] as? String, "iab")
    }

    func testUniversalIdsForwardedWithoutHcpProfile() {
        DocereeMobileAds.shared().setUniversalIds(
            rampId: "sha256:dtc-ramp",
            uid2: "dtc-uid2",
            id5: "",
            liveIntentId: "dtc-liveintent"
        )

        let body = DocereeAdRequest.shared.makeAdRequestBody(
            appKey: "app-key",
            userId: "device-id",
            user: HcpBuilder().build(),
            adUnitId: "ad-unit"
        )

        XCTAssertEqual(body[QueryParamsForAdRequest.hcpId.rawValue] as? String, "")
        XCTAssertEqual(body[QueryParamsForAdRequest.rampId.rawValue] as? String, "sha256:dtc-ramp")
        XCTAssertEqual(body[QueryParamsForAdRequest.uid2.rawValue] as? String, "dtc-uid2")
        XCTAssertEqual(body[QueryParamsForAdRequest.liveIntentId.rawValue] as? String, "dtc-liveintent")
        XCTAssertNil(body[QueryParamsForAdRequest.id5.rawValue])
    }

    func testAdRequestBodyNestsConsentUnderCnsWithExpectedShape() {
        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: HcpBuilder().build(),
            adUnitId: "unit",
            consent: CollectedConsent(
                consent: DocereeConsent(
                    userConsent: "1",
                    privacyType: "ccpa",
                    privacyString: "COvFyGgOvFyGgADACHENAPCgAAAAAH_AACiQBAAIAA",
                    privacySid: ["2", "6"],
                    privacyVersion: "9.0"
                ),
                source: .explicit
            ),
            universalIds: UniversalIds(),
            br: ""
        )

        let cns = body[QueryParamsForAdRequest.consent.rawValue] as? [String: Any]
        XCTAssertNotNil(cns)
        XCTAssertEqual(cns?[ConsentPayloadKey.userPreference.rawValue] as? String, "1")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyType.rawValue] as? String, "ccpa")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyVersion.rawValue] as? String, "9.0")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyString.rawValue] as? String, "COvFyGgOvFyGgADACHENAPCgAAAAAH_AACiQBAAIAA")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacySectionIDs.rawValue] as? [String], ["2", "6"])
        XCTAssertNil(body[ConsentPayloadKey.userPreference.rawValue])
        XCTAssertEqual(cns?[ConsentPayloadKey.consentSource.rawValue] as? String, "explicit")
    }

    func testMalformedConsentStringDoesNotCrashCollector() {
        defaultsManager.setConsentData(
            isPersonalizeAd: "not-a-flag",
            privacyComplianceType: "???",
            privacyComplianceVersion: "bad",
            privacyComplianceSID: "not,valid,but,forwarded",
            privacyString: "%%%%broken%%%%"
        )
        let signals = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collectLegacySignals()
        XCTAssertEqual(signals.privacyString, "%%%%broken%%%%")
    }

    func testHealthAssociateAdRequestUsesRoleSpecificPayload() {
        let user = HealthAssociateBuilder()
            .setFirstName("Sarah")
            .setAssociateId("STAFF-77123")
            .setAssociateRole("registered_nurse")
            .setDepartment("Cardiology")
            .build()

        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: user,
            adUnitId: "unit",
            consent: CollectedConsent(consent: DocereeConsent()),
            universalIds: UniversalIds(),
            br: "",
            role: .ha
        )

        XCTAssertEqual(body[QueryParamsForAdRequest.role.rawValue] as? String, "ha")
        XCTAssertEqual(body[QueryParamsForAdRequest.associateId.rawValue] as? String, "STAFF-77123")
        XCTAssertNil(body[QueryParamsForAdRequest.hcpId.rawValue])
        XCTAssertNil(body[QueryParamsForAdRequest.specialization.rawValue])
    }

    func testDefaultHcpAdRequestKeepsLegacyPayloadShape() {
        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: HcpBuilder()
                .setSpecialization("Pediatrics")
                .setHcpId("HCP-1001")
                .setMobile("+12125550100")
                .setHashedEmail("sha256:c84d9f2e")
                .setHashedMobile("sha256:b94d27e2")
                .setDateOfBirth("1978-04-12")
                .build(),
            adUnitId: "unit",
            consent: CollectedConsent(consent: DocereeConsent()),
            universalIds: UniversalIds(),
            br: ""
        )

        XCTAssertNil(body[QueryParamsForAdRequest.role.rawValue])
        XCTAssertEqual(body[QueryParamsForAdRequest.specialization.rawValue] as? String, "Pediatrics")
        XCTAssertEqual(body[QueryParamsForAdRequest.hcpId.rawValue] as? String, "HCP-1001")
        XCTAssertEqual(body[QueryParamsForAdRequest.mobile.rawValue] as? String, "+12125550100")
        XCTAssertEqual(body[QueryParamsForAdRequest.hashedEmail.rawValue] as? String, "sha256:c84d9f2e")
        XCTAssertEqual(body[QueryParamsForAdRequest.hashedMobile.rawValue] as? String, "sha256:b94d27e2")
        XCTAssertEqual(body[QueryParamsForAdRequest.dateOfBirth.rawValue] as? String, "1978-04-12")
        XCTAssertNil(body[QueryParamsForAdRequest.associateId.rawValue])
    }

    func testMergedPrivacyAndPublisherAttestedConsentInCns() {
        defaultsManager.saveConsent(
            DocereeConsentBuilder()
                .setUserConsent("1")
                .setPrivacyType("tcf")
                .setPrivacyString("1YNN")
                .setPrivacyVersion("2.0")
                .setPrivacySid("1,2,3,7")
                .build()
        )
        defaultsManager.saveConsent(
            DocereeConsentBuilder()
                .setConsentBasis("publisher_attested")
                .setMechanism("publisher_onboarding")
                .setGrantedAt("2026-08-05T10:00:00Z")
                .setExpiresAt("2027-08-05T10:00:00Z")
                .setConsentReferenceId("CONSENT-HCP-1001")
                .build()
        )

        let collected = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collect()
        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: HcpBuilder().build(),
            adUnitId: "unit",
            consent: collected,
            universalIds: UniversalIds(),
            br: ""
        )

        let cns = body[QueryParamsForAdRequest.consent.rawValue] as? [String: Any]
        XCTAssertEqual(cns?[ConsentPayloadKey.userPreference.rawValue] as? String, "1")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyType.rawValue] as? String, "tcf")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyString.rawValue] as? String, "1YNN")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacyVersion.rawValue] as? String, "2.0")
        XCTAssertEqual(cns?[ConsentPayloadKey.privacySectionIDs.rawValue] as? [String], ["1", "2", "3", "7"])
        XCTAssertEqual(cns?[PublisherAttestedConsentKey.consentBasis.rawValue] as? String, "publisher_attested")
        XCTAssertEqual(cns?[PublisherAttestedConsentKey.consentReferenceId.rawValue] as? String, "CONSENT-HCP-1001")
    }

    func testPrivacyConsentUpdatePreservesPublisherAttestedFields() {
        defaultsManager.saveConsent(
            DocereeConsentBuilder()
                .setConsentReferenceId("CONSENT-HCP-1001")
                .build()
        )
        defaultsManager.saveConsent(
            DocereeConsentBuilder()
                .setUserConsent("1")
                .setPrivacyType("tcf")
                .build()
        )

        let collected = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collect()
        XCTAssertEqual(collected.consent.userConsent, "1")
        XCTAssertEqual(collected.consent.privacyType, "tcf")
        XCTAssertEqual(collected.consent.consentReferenceId, "CONSENT-HCP-1001")
    }

    func testCommonConsentIsSharedAcrossAdRequests() {
        let consent = DocereeConsentBuilder()
            .setUserConsent("1")
            .setPrivacyType("tcf")
            .setConsentReferenceId("CONSENT-1001")
            .build()

        defaultsManager.saveConsent(consent)

        let collected = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collect()
        XCTAssertEqual(collected.consent.userConsent, "1")
        XCTAssertEqual(collected.consent.consentReferenceId, "CONSENT-1001")

        let updated = DocereeConsentBuilder()
            .setUserConsent("0")
            .setConsentReferenceId("CONSENT-2001")
            .build()
        defaultsManager.saveConsent(updated)

        let afterUpdate = ConsentSignalCollector(defaultsManager: defaultsManager, iabDefaults: iabDefaults).collect()
        XCTAssertEqual(afterUpdate.consent.userConsent, "0")
        XCTAssertEqual(afterUpdate.consent.consentReferenceId, "CONSENT-2001")
    }

    func testUnifiedConsentIncludesPublisherAttestedFieldsInCns() {
        let consent = CollectedConsent(
            consent: DocereeConsentBuilder()
                .setUserConsent("1")
                .setPrivacyType("tcf")
                .setPrivacyString("1YNN")
                .setConsentBasis("publisher_attested")
                .setMechanism("publisher_onboarding")
                .setGrantedAt("2026-08-05T10:00:00Z")
                .setExpiresAt("2027-08-05T10:00:00Z")
                .setConsentReferenceId("CONSENT-HCP-1001")
                .build(),
            source: .explicit
        )

        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: HcpBuilder().build(),
            adUnitId: "unit",
            consent: consent,
            universalIds: UniversalIds(),
            br: ""
        )

        let cns = body[QueryParamsForAdRequest.consent.rawValue] as? [String: Any]
        XCTAssertEqual(cns?[ConsentPayloadKey.userPreference.rawValue] as? String, "1")
        XCTAssertEqual(cns?[PublisherAttestedConsentKey.consentBasis.rawValue] as? String, "publisher_attested")
        XCTAssertEqual(cns?[PublisherAttestedConsentKey.consentReferenceId.rawValue] as? String, "CONSENT-HCP-1001")
    }

    private func clearIABDefaults() {
        [
            IABConsentStorageKeys.gppString,
            IABConsentStorageKeys.gppSID,
            IABConsentStorageKeys.gppVersion,
            IABConsentStorageKeys.tcfString,
            IABConsentStorageKeys.tcfPolicyVersion,
            IABConsentStorageKeys.gdprApplies
        ].forEach { iabDefaults.removeObject(forKey: $0) }
    }
}

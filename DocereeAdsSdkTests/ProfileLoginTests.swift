import XCTest
@testable import DocereeAdsSdk

final class ProfileLoginTests: XCTestCase {

    private var profileDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        profileDefaults = UserDefaults(suiteName: "ProfileLoginTests.\(UUID().uuidString)")!
        UserDefaultsManager.shared.resetLoggedInProfileForTesting()
        DocereeMobileAds.clearUserData()
    }

    override func tearDown() {
        UserDefaultsManager.shared.resetLoggedInProfileForTesting()
        DocereeMobileAds.clearUserData()
        profileDefaults = nil
        super.tearDown()
    }

    func testUnifiedLoginAcceptsHcpBuilder() {
        let builder = HcpBuilder()
            .setFirstName("John")
            .setLastName("Doe")
            .setHcpId("HCP-1001")

        DocereeMobileAds.login(with: builder)

        let profile = DocereeMobileAds.shared().getProfile()
        XCTAssertEqual(profile?.fullName, "John Doe")
        XCTAssertEqual(profile?.hcpId, "HCP-1001")
        XCTAssertEqual(profile?.role, .hcp)
    }

    func testUnifiedLoginAcceptsHealthAssociateBuilder() {
        let builder = HealthAssociateBuilder()
            .setFirstName("Sarah")
            .setLastName("Mitchell")
            .setAssociateId("STAFF-77123")
            .setAssociateRole("registered_nurse")

        DocereeMobileAds.login(with: builder)

        let profile = DocereeMobileAds.shared().getProfile()
        XCTAssertEqual(profile?.role, .ha)
        XCTAssertEqual(profile?.associateId, "STAFF-77123")
        XCTAssertEqual(profile?.associateRole, "registered_nurse")
    }

    func testUnifiedLoginAcceptsUserBuilder() {
        let builder = UserBuilder()
            .setFirstName("Jane")
            .setLastName("Doe")
            .setEmail("patient@email.com")

        DocereeMobileAds.login(with: builder)

        let profile = DocereeMobileAds.shared().getProfile()
        XCTAssertEqual(profile?.role, .user)
        XCTAssertEqual(profile?.email, "patient@email.com")
        XCTAssertNil(profile?.patientId)
        XCTAssertNil(profile?.hashedPatientId)
    }

    func testLatestLoginOverridesPreviousUserType() {
        DocereeMobileAds.login(with: HcpBuilder().setHcpId("HCP-OLD"))
        XCTAssertEqual(DocereeMobileAds.shared().getProfile()?.role, .hcp)

        DocereeMobileAds.login(with: HealthAssociateBuilder().setAssociateId("STAFF-NEW"))
        XCTAssertEqual(DocereeMobileAds.shared().getProfile()?.role, .ha)
        XCTAssertEqual(DocereeMobileAds.shared().getProfile()?.associateId, "STAFF-NEW")
        XCTAssertNil(DocereeMobileAds.shared().getProfile()?.hcpId)

        DocereeMobileAds.login(with: UserBuilder().setEmail("new-patient@email.com"))
        XCTAssertEqual(DocereeMobileAds.shared().getProfile()?.role, .user)
        XCTAssertEqual(DocereeMobileAds.shared().getProfile()?.email, "new-patient@email.com")
        XCTAssertNil(DocereeMobileAds.shared().getProfile()?.associateId)
    }

    func testBuilderTypeDeterminesStoredRoleNotBuiltProfileDefault() {
        DocereeMobileAds.login(with: HealthAssociateBuilder().setAssociateId("STAFF-ROLE"))

        XCTAssertEqual(UserDefaultsManager.shared.loggedInUserRole(), .ha)
        XCTAssertEqual(DocereeMobileAds.shared().getProfile()?.role, .ha)
        XCTAssertEqual(DocereeMobileAds.shared().getProfile()?.associateId, "STAFF-ROLE")
    }

    func testUserAdRequestUsesRoleSpecificPayload() {
        DocereeMobileAds.login(with: UserBuilder()
            .setFirstName("Jane")
            .setLastName("Doe")
            .setUserType("DTC")
            .setSpecialization("Pediatrics")
            .setOrganisation("Apollo")
            .setEmail("patient@email.com")
            .setHcpId("USER-1001")
            .setHashedHcpId("sha256:user1001"))

        let user = DocereeMobileAds.shared().getProfile()!
        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: user,
            adUnitId: "unit",
            consent: ConsentSignals(),
            universalIds: UniversalIds(),
            br: ""
        )

        XCTAssertEqual(body[QueryParamsForAdRequest.role.rawValue] as? String, "user")
        XCTAssertEqual(body[QueryParamsForAdRequest.userType.rawValue] as? String, "DTC")
        XCTAssertEqual(body[QueryParamsForAdRequest.email.rawValue] as? String, "patient@email.com")
        XCTAssertEqual(body[QueryParamsForAdRequest.specialization.rawValue] as? String, "Pediatrics")
        XCTAssertEqual(body[QueryParamsForAdRequest.organisation.rawValue] as? String, "Apollo")
        XCTAssertEqual(body[QueryParamsForAdRequest.hcpId.rawValue] as? String, "USER-1001")
        XCTAssertEqual(body[QueryParamsForAdRequest.hashedHcpId.rawValue] as? String, "sha256:user1001")
        XCTAssertNil(body[QueryParamsForAdRequest.patientId.rawValue])
        XCTAssertNil(body[QueryParamsForAdRequest.hashedPatientId.rawValue])
        XCTAssertNil(body[QueryParamsForAdRequest.associateId.rawValue])
    }

    func testPublisherAttestedConsentFromBuilderIsForwardedInCns() {
        DocereeMobileAds.login(with: HcpBuilder()
            .setHcpId("HCP-1001")
            .setConsent(PublisherAttestedConsentBuilder()
                .setConsentBasis("publisher_attested")
                .setMechanism("publisher_onboarding")
                .setGrantedAt("2024-03-10T08:30:00Z")
                .setExpiresAt("2025-03-10T08:30:00Z")
                .setConsentReferenceId("CONSENT-HCP-44821")
                .build()))

        let user = DocereeMobileAds.shared().getProfile()!
        let body = AdRequestPayloadAssembler.makeBody(
            appKey: "app",
            userId: "user",
            user: user,
            adUnitId: "unit",
            consent: ConsentSignals(),
            universalIds: UniversalIds(),
            br: ""
        )

        let cns = body[QueryParamsForAdRequest.consent.rawValue] as? [String: Any]
        XCTAssertEqual(cns?[PublisherAttestedConsentKey.consentBasis.rawValue] as? String, "publisher_attested")
        XCTAssertEqual(cns?[PublisherAttestedConsentKey.mechanism.rawValue] as? String, "publisher_onboarding")
        XCTAssertEqual(cns?[PublisherAttestedConsentKey.grantedAt.rawValue] as? String, "2024-03-10T08:30:00Z")
        XCTAssertEqual(cns?[PublisherAttestedConsentKey.expiresAt.rawValue] as? String, "2025-03-10T08:30:00Z")
        XCTAssertEqual(cns?[PublisherAttestedConsentKey.consentReferenceId.rawValue] as? String, "CONSENT-HCP-44821")
    }
}

import XCTest
@testable import DocereeAdsSdk

final class HcpProfileTests: XCTestCase {

    func testFullNameJoinsFirstAndLastName() {
        let hcp = HcpBuilder()
            .setFirstName("Jane")
            .setLastName("Doe")
            .build()

        XCTAssertEqual(hcp.fullName, "Jane Doe")
    }

    func testFullNameOmitsMissingParts() {
        let hcp = HcpBuilder()
            .setFirstName("Jane")
            .build()

        XCTAssertEqual(hcp.fullName, "Jane")
    }

    func testSecureCodingRoundTripPreservesProfileFields() throws {
        let original = HcpBuilder()
            .setFirstName("Jane")
            .setLastName("Doe")
            .setEmail("jane@example.com")
            .setHcpId("HCP-1001")
            .setHashedHcpId("sha256:hcp")
            .build()

        let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
        let decoded = try XCTUnwrap(
            NSKeyedUnarchiver.unarchivedObject(ofClasses: [Hcp.self, NSString.self, NSNumber.self], from: data) as? Hcp
        )

        XCTAssertEqual(decoded.fullName, "Jane Doe")
        XCTAssertEqual(decoded.email, "jane@example.com")
        XCTAssertEqual(decoded.hcpId, "HCP-1001")
        XCTAssertEqual(decoded.hashedHcpId, "sha256:hcp")
        XCTAssertEqual(decoded.role, .hcp)
    }

    func testDefaultRoleIsUserForUserBuilder() {
        let user = UserBuilder().build()
        XCTAssertEqual(user.role, .user)
    }

    func testSecureCodingRoundTripPreservesUserBuilderFields() throws {
        let original = UserBuilder()
            .setFirstName("Jane")
            .setLastName("Doe")
            .setUserType("HCP")
            .setSpecialization("Pediatrics")
            .setOrganisation("Apollo")
            .setHcpId("USER-1001")
            .build()

        let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
        let decoded = try XCTUnwrap(
            NSKeyedUnarchiver.unarchivedObject(ofClasses: [Hcp.self, NSString.self, NSNumber.self], from: data) as? Hcp
        )

        XCTAssertEqual(decoded.role, .user)
        XCTAssertEqual(decoded.userType, "HCP")
        XCTAssertEqual(decoded.specialization, "Pediatrics")
        XCTAssertEqual(decoded.organisation, "Apollo")
        XCTAssertEqual(decoded.hcpId, "USER-1001")
    }

    func testDefaultRoleIsHcp() {
        let hcp = HcpBuilder().build()
        XCTAssertEqual(hcp.role, .hcp)
    }

    func testSecureCodingRoundTripPreservesHealthAssociateFields() throws {
        let original = HealthAssociateBuilder()
            .setFirstName("Alex")
            .setLastName("Smith")
            .setAssociateId("STAFF-77123")
            .setHashedAssociateId("sha256:d44f1a2b3c4d5e6f")
            .setAssociateRole("registered_nurse")
            .setDepartment("Cardiology")
            .setClinicalInfluenceTier(1)
            .setDateOfBirth("1985-04-22")
            .setHashedMobile("sha256:f66b1c2d3e4f5a6b")
            .build()
            .applyingRole(.ha)

        let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
        let decoded = try XCTUnwrap(
            NSKeyedUnarchiver.unarchivedObject(ofClasses: [Hcp.self, NSString.self, NSNumber.self], from: data) as? Hcp
        )

        XCTAssertEqual(decoded.role, .ha)
        XCTAssertEqual(decoded.associateId, "STAFF-77123")
        XCTAssertEqual(decoded.hashedAssociateId, "sha256:d44f1a2b3c4d5e6f")
        XCTAssertEqual(decoded.associateRole, "registered_nurse")
        XCTAssertEqual(decoded.department, "Cardiology")
        XCTAssertEqual(decoded.clinicalInfluenceTier, 1)
        XCTAssertEqual(decoded.dateOfBirth, "1985-04-22")
        XCTAssertEqual(decoded.hashedMobile, "sha256:f66b1c2d3e4f5a6b")
    }

    func testLegacyProfileWithoutRoleDefaultsToHcp() throws {
        let legacy = HcpBuilder()
            .setFirstName("Legacy")
            .build()
        let data = try NSKeyedArchiver.archivedData(withRootObject: legacy, requiringSecureCoding: true)

        guard let decoded = try NSKeyedUnarchiver.unarchivedObject(
            ofClasses: [Hcp.self, NSString.self, NSNumber.self],
            from: data
        ) as? Hcp else {
            XCTFail("Expected Hcp")
            return
        }

        XCTAssertEqual(decoded.role, .hcp)
    }
}

import XCTest
@testable import DocereeAdsSdk

final class HcpProfileTests: XCTestCase {

    func testFullNameJoinsFirstAndLastName() {
        let hcp = Hcp.HcpBuilder()
            .setFirstName(firstName: "Jane")
            .setLastName(lastName: "Doe")
            .build()

        XCTAssertEqual(hcp.fullName, "Jane Doe")
    }

    func testFullNameOmitsMissingParts() {
        let hcp = Hcp.HcpBuilder()
            .setFirstName(firstName: "Jane")
            .build()

        XCTAssertEqual(hcp.fullName, "Jane")
    }

    func testSecureCodingRoundTripPreservesProfileFields() throws {
        let original = Hcp.HcpBuilder()
            .setFirstName(firstName: "Jane")
            .setLastName(lastName: "Doe")
            .setEmail(email: "jane@example.com")
            .setHcpId(hcpId: "HCP-1001")
            .setHashedHcpId(hashedHcpId: "sha256:hcp")
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

    func testDefaultRoleIsHcp() {
        let hcp = Hcp.HcpBuilder().build()
        XCTAssertEqual(hcp.role, .hcp)
    }

    func testSecureCodingRoundTripPreservesHealthAssociateFields() throws {
        let original = Hcp.HcpBuilder()
            .setRole(.ha)
            .setFirstName(firstName: "Alex")
            .setLastName(lastName: "Smith")
            .setAssociateId(associateId: "STAFF-77123")
            .setHashedAssociateId(hashedAssociateId: "sha256:d44f1a2b3c4d5e6f")
            .setAssociateRole(associateRole: "registered_nurse")
            .setDepartment(department: "Cardiology")
            .setClinicalInfluenceTier(clinicalInfluenceTier: 1)
            .setDateOfBirth(dateOfBirth: "1985-04-22")
            .setHashedMobile(hashedMobile: "sha256:f66b1c2d3e4f5a6b")
            .build()

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
        let legacy = Hcp.HcpBuilder()
            .setFirstName(firstName: "Legacy")
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

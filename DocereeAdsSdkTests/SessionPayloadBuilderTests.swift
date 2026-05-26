import XCTest
@testable import DocereeAdsSdk

final class SessionPayloadBuilderTests: XCTestCase {
    func testSessionPayloadToJsonOmitsEmptyDefaultBuilder() {
        let json = SessionPayloadBuilder().build().toJson()
        XCTAssertTrue(json.isEmpty, "All-default payload fields should be filtered out")
    }

    func testSessionPayloadToJsonIncludesAgeUnderPatientDataKey() {
        let json = SessionPayloadBuilder().add(key: "age", value: "42").build().toJson()
        XCTAssertEqual(json["ag"] as? String, "42")
    }

    func testSessionPayloadToJsonIncludesSessionIdUnderPatientDataKey() {
        let json = SessionPayloadBuilder().add(key: "sessionId", value: "sess-1").build().toJson()
        XCTAssertEqual(json["sid"] as? String, "sess-1")
    }

    func testSessionDetailsPreservesCanonicalSessionKeys() {
        let payload: [[String: Any]] = [
            ["dxCode": "E11.9", "status": "active"]
        ]
        let sessionDetails: [String: Any] = ["diagnosis_v1": payload]
        let json = SessionPayloadBuilder().add(key: SessionPayloadBuilder.sessionDetailsKey, value: sessionDetails).build().toJson()
        let nested = json[SessionPayloadBuilder.sessionDetailsKey] as? [String: Any]
        let mapped = nested?["diagnosis_v1"] as? [[String: Any]]
        XCTAssertEqual(mapped?.count, 1)
        XCTAssertEqual(mapped?.first?["dxCode"] as? String, "E11.9")
    }

    func testSessionDetailsDeepMergesAcrossAdds() {
        let json = SessionPayloadBuilder()
            .add(key: SessionPayloadBuilder.sessionDetailsKey, value: ["diagnosis_v1": [["dxCode": "E11.9", "status": "active"]]])
            .add(key: SessionPayloadBuilder.sessionDetailsKey, value: ["heartRate": 72])
            .build()
            .toJson()
        let nested = json[SessionPayloadBuilder.sessionDetailsKey] as? [String: Any]
        XCTAssertEqual((nested?["heartRate"] as? Int), 72)
        let dx = nested?["diagnosis_v1"] as? [[String: Any]]
        XCTAssertEqual(dx?.first?["dxCode"] as? String, "E11.9")
    }

    func testActionEventValidationRejectsMissingAppointmentCommonFields() {
        let invalidAction: [String: Any] = [
            "type": "appt_request",
            "timestamp": "2026-01-01T10:00:00Z",
            "patientId": "pat-1"
        ]

        let json = SessionPayloadBuilder().add(key: SessionPayloadBuilder.actionEventKey, value: invalidAction).build().toJson()
        XCTAssertNil(json[SessionPayloadBuilder.actionEventKey], "Invalid appointment action should be dropped")
    }

    func testActionEventValidationAcceptsRequiredAppointmentCommonFields() {
        let validAction: [String: Any] = [
            "type": "appt_request",
            "timestamp": "2026-01-01T10:00:00Z",
            "patientId": "pat-1",
            "appointmentId": "appt-1"
        ]

        let json = SessionPayloadBuilder().add(key: SessionPayloadBuilder.actionEventKey, value: validAction).build().toJson()
        let events = json[SessionPayloadBuilder.actionEventKey] as? [[String: Any]]
        XCTAssertEqual(events?.count, 1)
        XCTAssertEqual(events?.first?["appointmentId"] as? String, "appt-1")
    }

    func testUserDetailsAndHealthAssociateArePreserved() {
        let userDetails: [String: Any] = [
            "hcpId": "HCP-1001",
            "hashedHcpId": "sha256:hcp1001",
            "email": "hcp@example.com",
            "mobile": "+1-555-000-4444",
            "hashedEmail": "sha256:email",
            "hashedMobile": "sha256:mobile",
            "firstName": "John",
            "lastName": "Doe",
            "gender": "m",
            "country": "US",
            "state": "CA",
            "city": "SF",
            "zipCode": "94105",
            "dob": "1980-01-01",
            "specialization": "cardiology"
        ]
        let healthAssociate: [String: Any] = [
            "dateOfBirth": "1990-01-01",
            "gender": "f"
        ]

        let json = SessionPayloadBuilder()
            .add(key: SessionPayloadBuilder.userDetailsKey, value: userDetails)
            .add(key: SessionPayloadBuilder.healthAssociateKey, value: healthAssociate)
            .build()
            .toJson()

        let user = json[SessionPayloadBuilder.userDetailsKey] as? [String: Any]
        let associate = json[SessionPayloadBuilder.healthAssociateKey] as? [String: Any]
        XCTAssertEqual(user?["hcpId"] as? String, "HCP-1001")
        XCTAssertEqual(user?["hashedHcpId"] as? String, "sha256:hcp1001")
        XCTAssertEqual(user?["specialization"] as? String, "cardiology")
        XCTAssertEqual(associate?["gender"] as? String, "f")
    }

    func testPatientDetailsObjectIsPreserved() {
        let patientDetails: [String: Any] = [
            "patientId": "pat-11",
            "hashedId": "sha256:abc",
            "mobile": "+1-555-001"
        ]
        let json = SessionPayloadBuilder()
            .add(key: SessionPayloadBuilder.patientDetailsKey, value: patientDetails)
            .build()
            .toJson()
        let details = json[SessionPayloadBuilder.patientDetailsKey] as? [String: Any]
        XCTAssertEqual(details?["patientId"] as? String, "pat-11")
    }
}

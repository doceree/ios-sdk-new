import XCTest
@testable import DocereeAdsSdk

final class ActionAttributesATDMapperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "patientData")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "patientData")
        super.tearDown()
    }

    func testShortFormMapsLongActionEventKeys() {
        let event: [String: Any] = [
            "type": "appt_request",
            "timestamp": "2024-11-18T10:30:00Z",
            "appointmentId": "APT-2024-98712",
            "patientId": "PT-00112",
            "appointmentDate": "2024-11-18",
            "appointmentTime": "10:30",
            "visitType": "in_person",
            "hcpId": "1234567890",
            "hashedHcpId": "sha256:a3f9d72c4b6e8f1a",
            "visitUrgency": "routine",
            "facilityName": "Main Street Clinic",
            "facilityAddress": "123 Main St, New York, NY 10001",
            "facilityId": "FAC-001",
            "reasonForVisit": [[
                "chiefComplaint": "Worsening shortness of breath over past week",
                "symptomDuration": "7 days",
                "symptomSeverity": 6,
                "visitContext": "follow_up"
            ]]
        ]

        let shortEvent = ActionAttributesATDMapper.shortFormEvent(event)
        XCTAssertEqual(shortEvent["typ"] as? String, "appt_request")
        XCTAssertEqual(shortEvent["apid"] as? String, "APT-2024-98712")
        XCTAssertEqual(shortEvent["npi"] as? String, "1234567890")
        XCTAssertNil(shortEvent["type"])

        let reason = (shortEvent["rfv"] as? [[String: Any]])?.first
        XCTAssertEqual(reason?["cc"] as? String, "Worsening shortness of breath over past week")
        XCTAssertEqual(reason?["ssev"] as? Int, 6)
    }

    func testAtdPayloadWrapsEventsInEvtsArray() {
        let checkout: [String: Any] = [
            "type": "checkout",
            "timestamp": "2024-11-25T14:35:00Z",
            "appointmentId": "APT-2024-98712",
            "patientId": "PT-00112",
            "checkoutTimestamp": "2024-11-25T14:35:00Z",
            "visitDurationMinutes": 35,
            "billingStatus": "submitted",
            "providerNotesStatus": "signed",
            "followUpInstructions": "Increase Combivent to 3x daily if symptoms persist.",
            "referralIssued": true,
            "nextAppointmentScheduled": true,
            "nextAppointmentDate": "2024-12-16",
            "nextAppointmentTime": "09:00",
            "nextAppointmentFacilityId": "FAC-001",
            "nextAppointmentVisitType": "in_person",
            "facilityPhone": "+12125550100"
        ]

        let payload = ActionAttributesATDMapper.atdPayload(from: [checkout])
        let events = payload["evts"] as? [[String: Any]]
        XCTAssertEqual(events?.count, 1)
        XCTAssertEqual(events?.first?["typ"] as? String, "checkout")
        XCTAssertEqual(events?.first?["cots"] as? String, "2024-11-25T14:35:00Z")
        XCTAssertEqual(events?.first?["facph"] as? String, "+12125550100")
    }

    func testGetAtdEncodesEvtsWrapperWithShortKeys() {
        _ = DocereeMobileAds.shared().add(DocereeMobileAds.actionEventKey, value: [
            "type": "appt_request",
            "timestamp": "2026-08-05T10:00:00Z",
            "patientId": "PT-88012",
            "appointmentId": "APT-1"
        ])

        let decoded = decodeBase64JSONObject(PatientSession().getAtd())
        let events = decoded?["evts"] as? [[String: Any]]
        XCTAssertEqual(events?.count, 1)
        XCTAssertEqual(events?.first?["typ"] as? String, "appt_request")
        XCTAssertEqual(events?.first?["apid"] as? String, "APT-1")
        XCTAssertEqual(events?.first?["ptid"] as? String, "PT-88012")
    }

    private func decodeBase64JSONObject(_ encoded: String) -> [String: Any]? {
        guard let data = Data(base64Encoded: encoded),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
}

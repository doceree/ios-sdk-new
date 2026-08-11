import XCTest
@testable import DocereeAdsSdk

final class DocereeMobileAdsDataAttributesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "patientData")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "patientData")
        super.tearDown()
    }

    func testAddPatientDetailsPersistsByKey() {
        let patientData: [String: Any] = [
            "patientId": "PT-88012",
            "name": "Sam Patient"
        ]

        XCTAssertTrue(DocereeMobileAds.shared().add("patientDetails", value: patientData))

        let stored = StorageManager.shared.getPatientData()
        let details = stored?[DocereeMobileAds.patientDetailsKey] as? [String: Any]
        XCTAssertEqual(details?["patientId"] as? String, "PT-88012")
    }

    func testAddActionEventUpsertsByType() {
        let first: [String: Any] = [
            "type": "appt_request",
            "timestamp": "2026-08-05T10:00:00Z",
            "patientId": "PT-88012",
            "appointmentId": "APT-1"
        ]
        let updated: [String: Any] = [
            "type": "appt_request",
            "timestamp": "2026-08-05T11:00:00Z",
            "patientId": "PT-88012",
            "appointmentId": "APT-2"
        ]

        DocereeMobileAds.shared().add("actionEvent", value: first)
        DocereeMobileAds.shared().add("actionEvent", value: updated)

        let atd = PatientSession().getAtd()
        let events = decodeBase64JSONArray(atd)
        XCTAssertEqual(events?.count, 1)
        XCTAssertEqual(events?.first?["appointmentId"] as? String, "APT-2")
    }

    func testAddKeyValuePairsPersistSectionsForAdRequest() {
        _ = DocereeMobileAds.shared().add(DocereeMobileAds.patientDetailsKey, value: ["patientId": "PT-1"])
        _ = DocereeMobileAds.shared().add(DocereeMobileAds.sessionDetailsKey, value: ["heartRate": 72])
        _ = DocereeMobileAds.shared().add(DocereeMobileAds.actionEventKey, value: [
            "type": "checkout",
            "timestamp": "2026-08-05T10:00:00Z",
            "patientId": "PT-1",
            "appointmentId": "APT-1"
        ])

        XCTAssertFalse(PatientSession().getPtd().isEmpty)
        XCTAssertFalse(PatientSession().getBr().isEmpty)
        XCTAssertFalse(PatientSession().getAtd().isEmpty)
    }

    private func decodeBase64JSONArray(_ encoded: String) -> [[String: Any]]? {
        guard let data = Data(base64Encoded: encoded),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }
        return json
    }
}

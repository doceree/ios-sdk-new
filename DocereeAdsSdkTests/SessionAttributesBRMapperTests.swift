import XCTest
@testable import DocereeAdsSdk

final class SessionAttributesBRMapperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "patientData")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "patientData")
        super.tearDown()
    }

    func testShortFormMapsLongSessionDetailsKeys() {
        let sessionDetails: [String: Any] = [
            "sid": "b858df45-74e9-4cdb-99a3-3dfc26875602",
            "temperature": ["v": "98.6", "u": "F"],
            "bloodPressureSystolic": 128,
            "bloodPressureDiastolic": 82,
            "heartRate": 74,
            "oxygenSaturation": 98,
            "respiratoryRate": 16,
            "height": "5ft 9in",
            "weight": "182lbs",
            "bmi": 24.5,
            "vitalsRecordedAt": "2024-11-18T10:45:00Z",
            "pharmacy": ["CVS Pharmacy", "Walgreens"],
            "pharmacyFillHistory": [[
                "dispensedDate": "2024-10-18",
                "pharmacyName": "CVS Pharmacy",
                "ncpdpId": "5235731",
                "pharmacyNpi": "1234567890",
                "fills": [[
                    "ndc": "00002-2495-80",
                    "quantity": 90,
                    "daysSupply": 30,
                    "fillNumber": 2
                ]]
            ]],
            "diagnosis_v1": [[
                "dxCode": "J45.40",
                "status": "active"
            ]],
            "labtest_v1": [[
                "hcpcsCode": "85027",
                "testName": "Complete Blood Count",
                "resultStatus": "pending"
            ]],
            "prescription_v1": [[
                "rxCode": "00002-2495-80",
                "quantity": 90,
                "daysSupply": 30,
                "refillsRemaining": 3,
                "status": "active"
            ]],
            "labtesthistory_v1": [[
                "performedDate": "2024-08-10",
                "orderDate": "2024-08-10",
                "orderedByHcpId": "HCP-77123",
                "orderedByHashedHcpId": "sha256:b72c1a2b3c",
                "tests": [[
                    "hcpcsCode": "83036",
                    "testName": "HbA1c",
                    "resultStatus": "normal",
                    "resultValue": "6.8",
                    "resultUnit": "%"
                ]]
            ]],
            "diagnosishistory_v1": [[
                "encounterDate": "2019-03-12",
                "dxType": "ICD10",
                "diagnosedByHcpId": "HCP-77123",
                "diagnosedByHashedHcpId": "sha256:b72c1a2b3c",
                "encounterType": "office_visit",
                "diagnoses": [[
                    "dxCode": "E11.9",
                    "status": "chronic"
                ]]
            ]],
            "prescriptionhistory_v1": [[
                "prescribedDate": "2023-07-04",
                "rxType": 1,
                "prescribedByHcpId": "HCP-77123",
                "prescribedByHashedHcpId": "sha256:b72c1a2b3c",
                "prescriptions": [[
                    "rxCode": "00002-2495-80",
                    "quantity": 90,
                    "daysSupply": 30,
                    "status": "discontinued"
                ]]
            ]],
            "pharmacynotes_v1": [
                "00002-2495-80": ["Prefer pre-filled pens.", "Cold storage counsel."]
            ],
            "daw_v1": ["00002-2495-80", "00071-0155-23"],
            "session": 1
        ]

        let attributes = SessionAttributesBRMapper.shortForm(sessionDetails)

        XCTAssertEqual(attributes["sid"] as? String, "b858df45-74e9-4cdb-99a3-3dfc26875602")
        XCTAssertEqual(attributes["bps"] as? Int, 128)
        XCTAssertEqual(attributes["hr"] as? Int, 74)
        XCTAssertNil(attributes["session"])
        XCTAssertNil(attributes["heartRate"])

        let diagnosis = (attributes["dx_v1"] as? [[String: Any]])?.first
        XCTAssertEqual(diagnosis?["dxc"] as? String, "J45.40")

        let labTest = (attributes["lt_v1"] as? [[String: Any]])?.first
        XCTAssertEqual(labTest?["hcc"] as? String, "85027")

        let fill = ((attributes["phh_v1"] as? [[String: Any]])?.first?["fls"] as? [[String: Any]])?.first
        XCTAssertEqual(fill?["fno"] as? Int, 2)

        let historyTest = (((attributes["lth_v1"] as? [[String: Any]])?.first?["tsts"] as? [[String: Any]])?.first)
        XCTAssertEqual(historyTest?["rval"] as? String, "6.8")

        let brPayload = SessionAttributesBRMapper.brPayload(from: sessionDetails)
        XCTAssertNotNil(brPayload["attributes"] as? [String: Any])
    }

    func testGetBrEncodesAttributesWrapperWithShortKeys() {
        _ = DocereeMobileAds.shared().add(DocereeMobileAds.sessionDetailsKey, value: [
            "heartRate": 72,
            "diagnosis_v1": [["dxCode": "E11.9", "status": "active"]]
        ])
        _ = DocereeMobileAds.shared().add("sessionId", value: "sess-99")

        let decoded = decodeBase64JSONObject(PatientSession().getBr())
        let attributes = decoded?["attributes"] as? [String: Any]
        XCTAssertEqual(attributes?["sid"] as? String, "sess-99")
        XCTAssertEqual(attributes?["hr"] as? Int, 72)
        XCTAssertEqual(((attributes?["dx_v1"] as? [[String: Any]])?.first)?["dxc"] as? String, "E11.9")
        XCTAssertNil(decoded?["heartRate"])
    }

    private func decodeBase64JSONObject(_ encoded: String) -> [String: Any]? {
        guard let data = Data(base64Encoded: encoded),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
}

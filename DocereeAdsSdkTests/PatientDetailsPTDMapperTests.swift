import XCTest
@testable import DocereeAdsSdk

final class PatientDetailsPTDMapperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "patientData")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "patientData")
        super.tearDown()
    }

    func testShortFormMapsLongPatientDetailsKeys() {
        let patientDetails: [String: Any] = [
            "patientId": "PT-00112",
            "hashedId": "sha256:53b1390bdfa91dbb",
            "name": "Jane Doe",
            "dob": "1965-09-22",
            "mobile": "+12125550188",
            "email": "patient@email.com",
            "country": "US",
            "city": "New York",
            "hashedMobile": "sha256:bb22aabbccdd1122",
            "hashedEmail": "sha256:aa11aabbccdd1122",
            "state": "NY",
            "zipCode": "10001",
            "gender": "F",
            "age": "59",
            "ssn": "123-45-6789",
            "hashedSsn": "sha256:cc33aabbccdd1122",
            "consent": [
                "consentBasis": "publisher_attested",
                "mechanism": "patient_portal",
                "grantedAt": "2024-08-15T11:20:00Z",
                "expiresAt": "2025-08-15T11:20:00Z",
                "consentReferenceId": "CONSENT-PAT-884421"
            ],
            "insurance": [
                "hasInsurance": 1,
                "insuranceType": "commercial",
                "insuranceName": "Blue Cross Blue Shield",
                "insurancePlanName": "PPO Select",
                "insurancePlanId": "BCBS-PPO-001",
                "insuranceGroupId": "GRP-44821",
                "insuranceBin": "004336",
                "insurancePcn": "ADV",
                "insuranceMemberId": "XYZ123456789",
                "policyholderName": "John Doe",
                "policyholderDob": "1960-05-15",
                "relationshipToPolicyholder": "self",
                "primaryPayerPhone": "+18005551234"
            ],
            "clinicalProfile": [
                "smokingStatus": "never",
                "preferredPharmacy": [
                    "idType": 1,
                    "id": "1367084",
                    "name": "CVS Pharmacy - Main St"
                ],
                "newAllergies": [[
                    "allergen": "Penicillin",
                    "allergenType": "drug",
                    "reaction": "Hives, difficulty breathing",
                    "severity": "moderate",
                    "onsetDate": "2024-11-18",
                    "status": "active"
                ]],
                "newMedications": [[
                    "rxType": 1,
                    "rxCode": "00002-2495-80",
                    "medicationName": "Insulin glargine",
                    "dosage": "10mg",
                    "frequency": "twice daily",
                    "startDate": "2024-11-18",
                    "endDate": "2025-11-18",
                    "status": "active"
                ]],
                "surgicalHistory": [[
                    "procedureName": "Appendectomy",
                    "procedureCode": "44970",
                    "procedureDate": "2015-06-10",
                    "procedureType": "laparoscopic"
                ]],
                "familyHistory": [[
                    "conditionName": "Type 2 Diabetes",
                    "conditionCode": "E11.9",
                    "relation": "mother",
                    "genetic": true
                ]],
                "socialHistory": [
                    "tobaccoUse": "never",
                    "alcoholUse": "social",
                    "substanceUse": "none",
                    "physicalActivity": "moderate"
                ]
            ],
            "siteId": "2620"
        ]

        let shortForm = PatientDetailsPTDMapper.shortForm(patientDetails)

        XCTAssertEqual(shortForm["pid"] as? String, "PT-00112")
        XCTAssertEqual(shortForm["hpid"] as? String, "sha256:53b1390bdfa91dbb")
        XCTAssertEqual(shortForm["pname"] as? String, "Jane Doe")
        XCTAssertEqual(shortForm["zip"] as? String, "10001")
        XCTAssertNil(shortForm["siteId"])
        XCTAssertNil(shortForm["patientId"])

        let consent = shortForm["cns"] as? [String: Any]
        XCTAssertEqual(consent?["bas"] as? String, "publisher_attested")
        XCTAssertEqual(consent?["crid"] as? String, "CONSENT-PAT-884421")

        let insurance = shortForm["ins"] as? [String: Any]
        XCTAssertEqual(insurance?["typ"] as? String, "commercial")
        XCTAssertEqual(insurance?["pid"] as? String, "BCBS-PPO-001")

        let clinical = shortForm["cp"] as? [String: Any]
        let pharmacy = clinical?["pph"] as? [String: Any]
        XCTAssertEqual(pharmacy?["idt"] as? Int, 1)
        XCTAssertEqual(pharmacy?["nm"] as? String, "CVS Pharmacy - Main St")

        let allergy = (clinical?["nalrg"] as? [[String: Any]])?.first
        XCTAssertEqual(allergy?["algn"] as? String, "Penicillin")

        let medication = (clinical?["nmed"] as? [[String: Any]])?.first
        XCTAssertEqual(medication?["mnm"] as? String, "Insulin glargine")

        let surgery = (clinical?["surg"] as? [[String: Any]])?.first
        XCTAssertEqual(surgery?["prnm"] as? String, "Appendectomy")

        let family = (clinical?["famh"] as? [[String: Any]])?.first
        XCTAssertEqual(family?["cdnm"] as? String, "Type 2 Diabetes")

        let social = clinical?["soc"] as? [String: Any]
        XCTAssertEqual(social?["phy"] as? String, "moderate")
    }

    func testGetPtdEncodesShortFormPatientDetails() {
        let patientDetails: [String: Any] = [
            "patientId": "PT-88012",
            "name": "Sam Patient",
            "gender": "M"
        ]

        _ = DocereeMobileAds.shared().add(DocereeMobileAds.patientDetailsKey, value: patientDetails)

        let decoded = decodeBase64JSONObject(PatientSession().getPtd())
        XCTAssertEqual(decoded?["pid"] as? String, "PT-88012")
        XCTAssertEqual(decoded?["pname"] as? String, "Sam Patient")
        XCTAssertEqual(decoded?["gd"] as? String, "M")
        XCTAssertNil(decoded?["patientId"])
    }

    private func decodeBase64JSONObject(_ encoded: String) -> [String: Any]? {
        guard let data = Data(base64Encoded: encoded),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
}

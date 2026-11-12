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
        let patientDetails = Self.janeDoePublisherPatientDetails()

        let shortForm = PatientDetailsPTDMapper.shortForm(patientDetails)

        XCTAssertEqual(shortForm["cntry"] as? String, "US")
        XCTAssertEqual(shortForm["state"] as? String, "NY")
        XCTAssertEqual(shortForm["gd"] as? String, "F")
        XCTAssertEqual(shortForm["ag"] as? String, "59")
        XCTAssertNil(shortForm["pid"])
        XCTAssertNil(shortForm["hpid"])
        XCTAssertNil(shortForm["pname"])
        XCTAssertNil(shortForm["pdob"])
        XCTAssertNil(shortForm["mob"])
        XCTAssertNil(shortForm["eml"])
        XCTAssertNil(shortForm["city"])
        XCTAssertNil(shortForm["zip"])
        XCTAssertNil(shortForm["ssn"])
        XCTAssertNil(shortForm["hssn"])
        XCTAssertNil(shortForm["siteId"])
        XCTAssertNil(shortForm["patientId"])

        let consent = shortForm["cns"] as? [String: Any]
        XCTAssertEqual(consent?["bas"] as? String, "publisher_attested")
        XCTAssertEqual(consent?["crid"] as? String, "CONSENT-PAT-884421")

        let insurance = shortForm["ins"] as? [String: Any]
        XCTAssertEqual(insurance?["has"] as? Int, 1)
        XCTAssertEqual(insurance?["typ"] as? String, "commercial")
        XCTAssertEqual(insurance?["pid"] as? String, "BCBS-PPO-001")
        XCTAssertEqual(insurance?["bin"] as? String, "004336")
        XCTAssertEqual(insurance?["pcn"] as? String, "ADV")
        XCTAssertEqual(insurance?["rel"] as? String, "self")
        XCTAssertEqual(insurance?["pph"] as? String, "+18005551234")
        XCTAssertNil(insurance?["nm"])
        XCTAssertNil(insurance?["pnm"])
        XCTAssertNil(insurance?["gid"])
        XCTAssertNil(insurance?["mid"])

        let clinical = shortForm["cp"] as? [String: Any]
        let pharmacy = clinical?["pph"] as? [String: Any]
        XCTAssertEqual(pharmacy?["idt"] as? Int, 1)
        XCTAssertEqual(pharmacy?["nm"] as? String, "CVS Pharmacy - Main St")

        let allergies = clinical?["nalrg"] as? [[String: Any]]
        XCTAssertEqual(allergies?.count, 3)
        XCTAssertEqual(allergies?.first?["algn"] as? String, "Penicillin")

        let medications = clinical?["nmed"] as? [[String: Any]]
        XCTAssertEqual(medications?.count, 3)

        let surgeries = clinical?["surg"] as? [[String: Any]]
        XCTAssertEqual(surgeries?.count, 3)

        let family = clinical?["famh"] as? [[String: Any]]
        XCTAssertEqual(family?.count, 4)

        let social = clinical?["soc"] as? [String: Any]
        XCTAssertEqual(social?["phy"] as? String, "moderate")
    }

    func testGetPtdEncodesShortFormPatientDetails() {
        let patientDetails: [String: Any] = [
            "patientId": "PT-88012",
            "name": "Sam Patient",
            "gender": "M",
            "country": "US"
        ]

        _ = DocereeMobileAds.shared().add(DocereeMobileAds.patientDetailsKey, value: patientDetails)

        let decoded = decodeBase64JSONObject(PatientSession().getPtd())
        XCTAssertEqual(decoded?["gd"] as? String, "M")
        XCTAssertEqual(decoded?["cntry"] as? String, "US")
        XCTAssertNil(decoded?["pid"])
        XCTAssertNil(decoded?["pname"])
        XCTAssertNil(decoded?["patientId"])
    }

    private func decodeBase64JSONObject(_ encoded: String) -> [String: Any]? {
        guard let data = Data(base64Encoded: encoded),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }

    private static func janeDoePublisherPatientDetails() -> [String: Any] {
        [
            "patientId": "PT-00112",
            "hashedId": TestHashFixtures.hashedPatientId,
            "name": "Jane Doe",
            "dob": "1965-09-22",
            "age": "59",
            "gender": "F",
            "email": "patient@email.com",
            "hashedEmail": TestHashFixtures.hashedEmailAlt,
            "mobile": "+12125550188",
            "hashedMobile": TestHashFixtures.hashedMobileAlt,
            "country": "US",
            "state": "NY",
            "city": "New York",
            "zipCode": "10001",
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
            "ssn": "123-45-6789",
            "hashedSsn": TestHashFixtures.hashedSsn,
            "consent": [
                "consentBasis": "publisher_attested",
                "mechanism": "patient_portal",
                "grantedAt": "2024-08-15T11:20:00Z",
                "expiresAt": "2025-08-15T11:20:00Z",
                "consentReferenceId": "CONSENT-PAT-884421"
            ],
            "clinicalProfile": [
                "smokingStatus": "never",
                "preferredPharmacy": [
                    "idType": 1,
                    "id": "1367084",
                    "name": "CVS Pharmacy - Main St"
                ],
                "newAllergies": [
                    [
                        "allergen": "Penicillin",
                        "allergenType": "drug",
                        "reaction": "Hives, difficulty breathing",
                        "severity": "moderate",
                        "onsetDate": "2024-11-18",
                        "status": "active"
                    ],
                    [
                        "allergen": "Peanuts",
                        "allergenType": "food",
                        "reaction": "Anaphylaxis",
                        "severity": "severe",
                        "onsetDate": "2018-03-12",
                        "status": "active"
                    ],
                    [
                        "allergen": "Latex",
                        "allergenType": "environment",
                        "reaction": "Skin rash",
                        "severity": "mild",
                        "onsetDate": "2020-08-10",
                        "status": "active"
                    ]
                ],
                "newMedications": [
                    [
                        "rxType": 1,
                        "rxCode": "00002-2495-80",
                        "medicationName": "Insulin glargine",
                        "dosage": "10 units",
                        "frequency": "twice daily",
                        "startDate": "2024-11-18",
                        "endDate": "2025-11-18",
                        "status": "active"
                    ],
                    [
                        "rxType": 1,
                        "rxCode": "54868-6157",
                        "medicationName": "Metformin",
                        "dosage": "500 mg",
                        "frequency": "once daily",
                        "startDate": "2024-10-01",
                        "endDate": "2025-11-18",
                        "status": "active"
                    ],
                    [
                        "rxType": 1,
                        "rxCode": "00093-7424-01",
                        "medicationName": "Lisinopril",
                        "dosage": "20 mg",
                        "frequency": "once daily",
                        "startDate": "2023-05-12",
                        "endDate": "2025-11-18",
                        "status": "active"
                    ]
                ],
                "surgicalHistory": [
                    [
                        "procedureName": "Appendectomy",
                        "procedureCode": "44970",
                        "procedureDate": "2015-06-10",
                        "procedureType": "laparoscopic"
                    ],
                    [
                        "procedureName": "Cholecystectomy",
                        "procedureCode": "47562",
                        "procedureDate": "2019-04-22",
                        "procedureType": "laparoscopic"
                    ],
                    [
                        "procedureName": "Left Knee Arthroscopy",
                        "procedureCode": "29881",
                        "procedureDate": "2021-09-15",
                        "procedureType": "arthroscopic"
                    ]
                ],
                "familyHistory": [
                    [
                        "conditionName": "Type 2 Diabetes",
                        "conditionCode": "E11.9",
                        "relation": "mother",
                        "genetic": true
                    ],
                    [
                        "conditionName": "Hypertension",
                        "conditionCode": "I10",
                        "relation": "father",
                        "genetic": true
                    ],
                    [
                        "conditionName": "Breast Cancer",
                        "conditionCode": "C50.919",
                        "relation": "sister",
                        "genetic": false
                    ],
                    [
                        "conditionName": "Coronary Artery Disease",
                        "conditionCode": "I25.10",
                        "relation": "grandfather",
                        "genetic": true
                    ]
                ],
                "socialHistory": [
                    "tobaccoUse": "never",
                    "alcoholUse": "social",
                    "substanceUse": "none",
                    "physicalActivity": "moderate"
                ]
            ],
            "siteId": "2620"
        ]
    }
}

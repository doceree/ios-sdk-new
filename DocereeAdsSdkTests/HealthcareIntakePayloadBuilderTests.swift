import XCTest
@testable import DocereeAdsSdk

final class HealthcareIntakePayloadBuilderTests: XCTestCase {
    func testBuildMapsPatientDetailsToIntakePayload() {
        let patientDetails: [String: Any] = [
            "siteId": "2620",
            "pubId": "5",
            "userid": "DE.V1.214113992724.1783930378300",
            "timestamp": "2026-07-21T07:05:22.170Z",
            "patientId": "PT-00112",
            "name": "Jane Doe",
            "dob": "1965-09-22",
            "gender": "F",
            "city": "New York",
            "state": "NY",
            "zipCode": "10001",
            "mobile": "+12125550188",
            "email": "patient@email.com",
            "ssn": "123-45-6789",
            "insurance": [
                "insurancePlanName": "PPO Select",
                "insuranceType": "commercial",
                "policyholderName": "John Doe",
                "policyholderDob": "1960-05-15",
                "relationshipToPolicyholder": "self",
                "insuranceMemberId": "XYZ123456789",
                "insuranceGroupId": "GRP-44821",
                "insuranceBin": "004336",
                "insurancePcn": "ADV",
                "primaryPayerPhone": "+18005551234"
            ],
            "clinicalProfile": [
                "preferredPharmacy": [
                    "name": "CVS Pharmacy - Main St"
                ],
                "newAllergies": [
                    [
                        "allergen": "Penicillin",
                        "reaction": "Hives, difficulty breathing"
                    ]
                ]
            ]
        ]

        let payload = HealthcareIntakePayloadBuilder.build(from: patientDetails)

        let patient = payload["patient"] as? [String: Any]
        XCTAssertEqual(patient?["first_name"] as? String, "Jane")
        XCTAssertEqual(patient?["last_name"] as? String, "Doe")
        XCTAssertEqual(patient?["ssn_last4"] as? String, "6789")

        let insurance = payload["insurance"] as? [String: Any]
        XCTAssertEqual(insurance?["plan_name"] as? String, "PPO Select")

        let routing = payload["routing"] as? [String: Any]
        XCTAssertEqual(routing?["patient_internal_id"] as? String, "PT-00112")

        let pharmacy = payload["pharmacy"] as? [String: Any]
        XCTAssertEqual(pharmacy?["name"] as? String, "CVS Pharmacy - Main St")

        let clinical = payload["clinical"] as? [String: Any]
        let allergies = clinical?["allergies"] as? [[String: String]]
        XCTAssertEqual(allergies?.first?["substance"], "Penicillin")

        XCTAssertEqual(payload["siteId"] as? String, "2620")
        XCTAssertEqual(payload["pubId"] as? String, "5")
        XCTAssertEqual(payload["userid"] as? String, "DE.V1.214113992724.1783930378300")
        XCTAssertEqual(payload["timestamp"] as? String, "2026-07-21T07:05:22.170Z")
    }

    func testBuildUsesBlankValuesWhenAppDoesNotProvideThem() {
        let payload = HealthcareIntakePayloadBuilder.build(from: [:])

        XCTAssertEqual(payload["siteId"] as? String, "")
        XCTAssertEqual(payload["pubId"] as? String, "")
        XCTAssertEqual(payload["userid"] as? String, "")
        XCTAssertEqual(payload["timestamp"] as? String, "")

        let patient = payload["patient"] as? [String: Any]
        XCTAssertEqual(patient?["first_name"] as? String, "")
        XCTAssertEqual(patient?["email"] as? String, "")

        let clinical = payload["clinical"] as? [String: Any]
        let allergies = clinical?["allergies"] as? [[String: String]]
        XCTAssertEqual(allergies?.count, 0)
    }

    func testBuildPassesThroughPreformattedIntakeSections() {
        let patientDetails: [String: Any] = [
            "patient": ["first_name": "Jane", "last_name": "Doe"],
            "insurance": ["plan_name": "PPO Select"],
            "routing": ["patient_internal_id": "PT-00112"],
            "pharmacy": ["name": "CVS Pharmacy - Main St"],
            "clinical": ["allergies": [["substance": "Penicillin", "reaction": "Hives"]]]
        ]

        let payload = HealthcareIntakePayloadBuilder.build(from: patientDetails)

        XCTAssertEqual((payload["patient"] as? [String: Any])?["first_name"] as? String, "Jane")
        XCTAssertEqual((payload["insurance"] as? [String: Any])?["plan_name"] as? String, "PPO Select")
        XCTAssertEqual((payload["routing"] as? [String: Any])?["patient_internal_id"] as? String, "PT-00112")
    }
}

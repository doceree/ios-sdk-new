import Foundation

/// Maps host-app patient JSON into the healthcare intake request body.
enum HealthcareIntakePayloadBuilder {
    static func build(from patientDetails: [String: Any]) -> [String: Any] {
        [
            "patient": buildPatientSection(from: patientDetails),
            "insurance": buildInsuranceSection(from: patientDetails),
            "routing": buildRoutingSection(from: patientDetails),
            "pharmacy": buildPharmacySection(from: patientDetails),
            "clinical": buildClinicalSection(from: patientDetails),
            "siteId": blankString(patientDetails["siteId"]),
            "pubId": blankString(patientDetails["pubId"]),
            "userid": blankString(patientDetails["userid"]),
            "timestamp": blankString(patientDetails["timestamp"])
        ]
    }

    private static func buildPatientSection(from details: [String: Any]) -> [String: Any] {
        if let nested = details["patient"] as? [String: Any] {
            return [
                "first_name": blankString(nested["first_name"] ?? nested["firstName"]),
                "last_name": blankString(nested["last_name"] ?? nested["lastName"]),
                "dob": blankString(nested["dob"]),
                "gender": blankString(nested["gender"]),
                "city": blankString(nested["city"]),
                "state": blankString(nested["state"]),
                "zip": blankString(nested["zip"] ?? nested["zipCode"]),
                "phone": blankString(nested["phone"] ?? nested["mobile"]),
                "email": blankString(nested["email"]),
                "ssn_last4": blankString(nested["ssn_last4"] ?? ssnLast4(from: nested["ssn"]))
            ]
        }

        let (splitFirst, splitLast) = splitName(details["name"] as? String)
        return [
            "first_name": blankString(details["firstName"] ?? details["first_name"] ?? splitFirst),
            "last_name": blankString(details["lastName"] ?? details["last_name"] ?? splitLast),
            "dob": blankString(details["dob"]),
            "gender": blankString(details["gender"]),
            "city": blankString(details["city"]),
            "state": blankString(details["state"]),
            "zip": blankString(details["zipCode"] ?? details["zip"]),
            "phone": blankString(details["mobile"] ?? details["phone"]),
            "email": blankString(details["email"]),
            "ssn_last4": blankString(ssnLast4(from: details["ssn"] ?? details["ssn_last4"]))
        ]
    }

    private static func buildInsuranceSection(from details: [String: Any]) -> [String: Any] {
        let source = details["insurance"] as? [String: Any] ?? [:]

        return [
            "plan_name": blankString(source["plan_name"] ?? source["insurancePlanName"] ?? source["insuranceName"]),
            "insurance_type": blankString(source["insurance_type"] ?? source["insuranceType"]),
            "policyholder_name": blankString(source["policyholder_name"] ?? source["policyholderName"]),
            "policyholder_dob": blankString(source["policyholder_dob"] ?? source["policyholderDob"]),
            "relationship_to_policyholder": blankString(
                source["relationship_to_policyholder"] ?? source["relationshipToPolicyholder"]
            ),
            "member_id": blankString(source["member_id"] ?? source["insuranceMemberId"]),
            "group_number": blankString(source["group_number"] ?? source["insuranceGroupId"]),
            "rxbin": blankString(source["rxbin"] ?? source["insuranceBin"]),
            "rxpcn": blankString(source["rxpcn"] ?? source["insurancePcn"]),
            "payer_phone": blankString(source["payer_phone"] ?? source["primaryPayerPhone"])
        ]
    }

    private static func buildRoutingSection(from details: [String: Any]) -> [String: Any] {
        let source = details["routing"] as? [String: Any] ?? [:]
        return [
            "patient_internal_id": blankString(source["patient_internal_id"] ?? details["patientId"])
        ]
    }

    private static func buildPharmacySection(from details: [String: Any]) -> [String: Any] {
        let pharmacy = details["pharmacy"] as? [String: Any]
        let preferred = (details["clinicalProfile"] as? [String: Any])?["preferredPharmacy"] as? [String: Any]
        return [
            "name": blankString(pharmacy?["name"] ?? preferred?["name"])
        ]
    }

    private static func buildClinicalSection(from details: [String: Any]) -> [String: Any] {
        if let clinical = details["clinical"] as? [String: Any],
           let allergies = clinical["allergies"] as? [[String: Any]] {
            return ["allergies": mapAllergies(allergies)]
        }

        if let clinicalProfile = details["clinicalProfile"] as? [String: Any],
           let allergies = clinicalProfile["newAllergies"] as? [[String: Any]] {
            return ["allergies": mapAllergies(allergies)]
        }

        if let clinicalProfile = details["clinicalProfile"] as? [String: Any],
           let allergies = clinicalProfile["allergies"] as? [[String: Any]] {
            return ["allergies": mapAllergies(allergies)]
        }

        return ["allergies": [[String: String]]()]
    }

    private static func mapAllergies(_ allergies: [[String: Any]]) -> [[String: String]] {
        allergies.map { allergy in
            [
                "substance": blankString(allergy["substance"] ?? allergy["allergen"]),
                "reaction": blankString(allergy["reaction"])
            ]
        }
    }

    private static func splitName(_ name: String?) -> (String?, String?) {
        guard let name, !name.isEmpty else { return (nil, nil) }
        let parts = name.split(separator: " ", maxSplits: 1).map(String.init)
        if parts.count == 2 {
            return (parts[0], parts[1])
        }
        return (parts.first, nil)
    }

    private static func ssnLast4(from value: Any?) -> String? {
        guard let raw = value as? String, !raw.isEmpty else { return nil }
        let digits = raw.filter(\.isNumber)
        if digits.count >= 4 {
            return String(digits.suffix(4))
        }
        return raw
    }

    private static func blankString(_ value: Any?) -> String {
        guard let string = value as? String else { return "" }
        return string
    }
}
